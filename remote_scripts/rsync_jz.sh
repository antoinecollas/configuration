#!/usr/bin/env bash
set -Eeuo pipefail

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

stage="resolve_work"
trap 'status=$?; printf "[jzrsync] event=failed stage=%s exit_code=%s\n" "$stage" "$status" >&2; exit "$status"' ERR
echo "[jzrsync] event=stage_start stage=resolve_work" >&2
work="$(
	ssh -o BatchMode=yes jz 'bash -lc "printf \"__JZ__%s__JZ__\" \"\$WORK\""' 2>/dev/null \
		| sed -n 's/.*__JZ__\(.*\)__JZ__.*/\1/p'
	)"
	work="$(printf %s "$work" | tr -d '\r\n')"
	[[ -z "$work" ]] && { echo "[jzrsync] event=failed stage=resolve_work reason=empty_work exit_code=1" >&2; exit 1; }

	dest="${work%/}/$subpath"
	stage=prepare_destination
	printf '[jzrsync] event=stage_start stage=prepare_destination destination=%q\n' "$dest" >&2
	ssh jz "bash -lc 'mkdir -p \"$dest\"'"

	RSYNC_ARGS=(-a --info=progress2 --partial)
	GIT_DIR=""

	if [ -d "$src/.git" ]; then
		echo '[jzrsync] event=sync_scope files=git_tracked message="Current contents, including uncommitted edits, plus Git metadata. Untracked files excluded."' >&2
		GIT_FILES_LIST=$(mktemp)
		RSYNC_ARGS+=(--files-from="$GIT_FILES_LIST")
		GIT_DIR="$src/.git"
	else
		echo '[jzrsync] event=sync_scope files=all message="No .git directory: copying all files, including untracked and ignored files."' >&2
	fi

	sync_once() {
		if [ -n "${GIT_FILES_LIST:-}" ]; then
			(cd "$src" && git ls-files) > "$GIT_FILES_LIST"
		fi

		rsync "${RSYNC_ARGS[@]}" "$src"/ "jz:${dest%/}/"

		if [ -n "$GIT_DIR" ]; then
			rsync -a --info=progress2 --partial --exclude='*.lock' \
				"$GIT_DIR"/ "jz:${dest%/}/.git/"
		fi
	}

	stage=initial_sync
	echo "[jzrsync] event=stage_start stage=initial_sync" >&2
	sync_once

	printf '[jzrsync] event=initial_sync_complete source=%q destination=%q\n' "$src" "jz:${dest%/}/" >&2
	stage=watch
	echo "[jzrsync] event=watch_start mode=continuous stop=ctrl-c" >&2
	while IFS= read -r _; do
		stage=sync_changes
		echo "[jzrsync] event=stage_start stage=sync_changes" >&2
		sync_once
		echo "[jzrsync] event=sync_complete" >&2
		stage=watch
	done < <(fswatch -r -o -l "${JZ_FSWATCH_LATENCY:-1.0}" "$src")
