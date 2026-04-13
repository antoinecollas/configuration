#!/usr/bin/env bash
set -euo pipefail

# vmrsync: continuously copy LOCAL_DIR -> HOST:BASE_DIR/SUBPATH (no deletions)

cleanup() {
    rm -f "${GIT_FILES_LIST:-}" || true
}
trap cleanup EXIT HUP INT TERM

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    cat <<'EOF'
Usage: vmrsync <HOST_OR_IP> [LOCAL_DIR] [REMOTE_SUBPATH]

Examples:
  vmrsync 203.0.113.10
  vmrsync root@203.0.113.10 ~/code/foo myproj

Environment:
  VM_BASE_DIR   Remote base directory. Relative paths are resolved under $HOME.
                Default: work
  VM_FSWATCH_LATENCY  Optional fswatch latency override
EOF
    exit 0
fi

if [[ "$#" -lt 1 || "$#" -gt 3 ]]; then
    echo "Usage: vmrsync <HOST_OR_IP> [LOCAL_DIR] [REMOTE_SUBPATH]" >&2
    exit 1
fi

host="$1"

if [[ "$host" == *@* ]]; then
    remote="$host"
else
    remote="root@${host}"
fi

local_arg="${2:-.}"
if [[ -d "$local_arg" ]]; then
    src="$(cd "$local_arg" && pwd -P)"
else
    echo "Local dir not found: $local_arg" >&2
    exit 1
fi

subpath="${3:-$(basename "$src")}"
if [[ -z "$subpath" || "$subpath" == /* ]]; then
    echo "Error: REMOTE_SUBPATH must be relative (no leading '/')." >&2
    exit 1
fi

remote_base_dir="${VM_BASE_DIR:-work}"

dest="$(
    ssh "$remote" bash -s -- "$remote_base_dir" "$subpath" <<'EOF'
set -euo pipefail

base_dir="$1"
subpath="$2"

if [[ "$base_dir" == /* ]]; then
    dest="${base_dir%/}/$subpath"
else
    dest="$HOME/${base_dir%/}/$subpath"
fi

mkdir -p "$dest"
printf '%s' "$dest"
EOF
)"
dest="$(printf %s "$dest" | tr -d '\r\n')"
[[ -z "$dest" ]] && { echo "Could not resolve remote destination on $remote" >&2; exit 1; }

RSYNC_ARGS=(-a --info=progress2 --partial --exclude=.git)

if [[ -d "$src/.git" ]]; then
    echo "Git repository detected. Only syncing files tracked by git."
    GIT_FILES_LIST=$(mktemp)
    (cd "$src" && git ls-files) > "$GIT_FILES_LIST"
    RSYNC_ARGS+=(--files-from="$GIT_FILES_LIST")
fi

echo "Initial copy -> ${remote}:${dest%/}/"
rsync "${RSYNC_ARGS[@]}" "$src"/ "${remote}:${dest%/}/"

echo "Watching $src -> ${remote}:${dest%/}/ (Ctrl-C to stop)"
fswatch -r -o -l "${VM_FSWATCH_LATENCY:-1.0}" "$src" | xargs -n1 -I{} rsync "${RSYNC_ARGS[@]}" "$src"/ "${remote}:${dest%/}/"
