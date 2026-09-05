#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    cat <<'EOF'
Usage: jzstart [LOCAL_DIR] [SUBPATH_UNDER_WORK]

Connect to Jean Zay, refresh local mounts, then continuously sync local files.
Agent-readable event and stage fields are printed to stderr. Stop synchronization with Ctrl-C.

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

stage="ssh"
trap 'status=$?; printf "[jzstart] event=failed stage=%s exit_code=%s\n" "$stage" "$status" >&2; exit "$status"' ERR

printf '[jzstart] event=start cluster=jean-zay source=%q remote_subpath=%q direction=local_to_remote delete=false\n' "$src" "$subpath" >&2
cat >&2 <<'EOF'
[jzstart] event=workflow message="SSH connection + live SSHFS mounts + one-way rsync over SSH, repeated by fswatch."
[jzstart] event=workflow message="Edit locally; remote edits do not sync back. Wait for initial_sync_complete, then sync_complete after edits."
[jzstart] event=workflow message="Keep running for sync. Ctrl-C stops the watcher; mounts and SSH remain."
EOF
echo "[jzstart] event=stage_start stage=ssh" >&2
if ! ssh -O check jz >/dev/null 2>&1; then
    echo "[jzstart] event=connecting stage=ssh authentication=may_require_user" >&2
    ssh -MNf jz
else
    echo "[jzstart] event=connection_reused stage=ssh" >&2
fi

stage="unmounting"
echo "[jzstart] event=stage_start stage=unmounting sudo=may_require_user" >&2
"$script_dir/umount_jz.sh"
stage="mounting"
echo "[jzstart] event=stage_start stage=mounting" >&2
"$script_dir/mount_jz.sh"
echo "[jzstart] event=handoff stage=sync mode=continuous stop=ctrl-c" >&2
exec "$script_dir/rsync_jz.sh" "$src" "$subpath"
