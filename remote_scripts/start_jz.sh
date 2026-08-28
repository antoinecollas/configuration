#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    cat <<'EOF'
Usage: jzstart [LOCAL_DIR] [SUBPATH_UNDER_WORK]

Examples:
  jzstart
  jzstart decoding
  jzstart decoding karavela/decoding

When SUBPATH_UNDER_WORK is omitted, it is derived from LOCAL_DIR relative to
$HOME. For example, ~/karavela/decoding becomes karavela/decoding.
EOF
    exit 0
fi

if [[ "$#" -gt 2 ]]; then
    echo "Usage: jzstart [LOCAL_DIR] [SUBPATH_UNDER_WORK]" >&2
    exit 1
fi

local_dir="${1:-.}"
if [[ -d "$local_dir" ]]; then
    src="$(cd "$local_dir" && pwd -P)"
else
    echo "Local dir not found: $local_dir" >&2
    exit 1
fi

if [[ "$#" -eq 2 ]]; then
    subpath="$2"
elif [[ "$src" == "$HOME/"* ]]; then
    subpath="${src#"$HOME"/}"
else
    echo "Cannot derive a remote path for a directory outside \$HOME." >&2
    echo "Provide SUBPATH_UNDER_WORK explicitly." >&2
    exit 1
fi

if [[ -z "$subpath" || "$subpath" == /* ]]; then
    echo "SUBPATH_UNDER_WORK must be relative and non-empty." >&2
    exit 1
fi

script_dir="$(cd "$(dirname "$0")" && pwd -P)"

if ! ssh -O check jz >/dev/null 2>&1; then
    ssh -MNf jz
fi

"$script_dir/umount_jz.sh"
"$script_dir/mount_jz.sh"
exec "$script_dir/rsync_jz.sh" "$src" "$subpath"
