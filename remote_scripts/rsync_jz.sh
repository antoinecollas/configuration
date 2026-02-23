#!/usr/bin/env bash
set -euo pipefail

# jzrsync: continuously copy LOCAL_DIR -> jz:$WORK/SUBPATH (no deletions)

# --- Ensure cleanup on exit ---
cleanup() {
    # This function will be called on script exit
    # to remove the temp file if it was created.
    # The '|| true' prevents errors if the file doesn't exist.
    rm -f "${GIT_FILES_LIST:-}" || true
}
trap cleanup EXIT HUP INT TERM

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "$#" -ne 2 ]]; then
	cat <<'EOF'
Usage: jzrsync <LOCAL_DIR> <SUBPATH_UNDER_WORK>

Examples:
  jzrsync ~/code/foo myproj
EOF
	exit 1
fi

if [ -d "$1" ]; then
	src="$(cd "$1" && pwd -P)"
else
	echo "Local dir not found: $1" >&2
	exit 1
fi

subpath="$2"
if [[ -z "$subpath" || "$subpath" == /* ]]; then
	echo "Error: second arg must be a SUBPATH (no leading '/')." >&2
	exit 1
fi

work="$(
	ssh -o BatchMode=yes jz 'bash -lc "printf \"__JZ__%s__JZ__\" \"\$WORK\""' 2>/dev/null \
		| sed -n 's/.*__JZ__\(.*\)__JZ__.*/\1/p'
	)"
	work="$(printf %s "$work" | tr -d '\r\n')"
	[[ -z "$work" ]] && { echo "Could not resolve \$WORK on jz"; exit 1; }

	dest="${work%/}/$subpath"
	ssh jz "bash -lc 'mkdir -p \"$dest\"'"

	RSYNC_ARGS=(-a --info=progress2 --partial)

	if [ -d "$src/.git" ]; then
		echo "Git repository detected. Only syncing files tracked by git."
		GIT_FILES_LIST=$(mktemp)
		(cd "$src" && git ls-files) > "$GIT_FILES_LIST"
		RSYNC_ARGS+=(--files-from="$GIT_FILES_LIST")
	fi

	echo "Initial copy → jz:${dest%/}/"
	rsync "${RSYNC_ARGS[@]}" "$src"/ "jz:${dest%/}/"

	echo "Watching $src → jz:${dest%/}/ (Ctrl-C to stop)"
	fswatch -r -o -l "${JZ_FSWATCH_LATENCY:-1.0}" "$src" | xargs -n1 -I{} rsync "${RSYNC_ARGS[@]}" "$src"/ "jz:${dest%/}/"
