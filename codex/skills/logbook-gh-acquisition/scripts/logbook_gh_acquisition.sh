#!/usr/bin/env bash
set -euo pipefail

REPO="karavela-ai/acquisition"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_cmd gh
require_cmd jq

LOGIN="${GITHUB_LOGIN:-$(gh api user -q .login)}"

format_section() {
  local title="$1"
  local query="$2"

  echo "## $title"

  local json
  json="$(gh search prs "$query" --repo "$REPO" --limit 100 --json number,title,url,updatedAt 2>/dev/null || echo '[]')"

  local count
  count="$(echo "$json" | jq 'length')"

  if [ "$count" -eq 0 ]; then
    echo "- None"
    echo
    return
  fi

  echo "$json" \
    | jq -r '
        sort_by(.updatedAt) | reverse | unique_by(.number) |
        .[] | "- \(.title) [(#\(.number))](\(.url))"
      '

  echo
}

format_section "Merged PRs" "author:${LOGIN} is:merged"
format_section "Open PRs"   "author:${LOGIN} is:open"
format_section "Reviews"    "reviewed-by:${LOGIN} -author:${LOGIN} is:pr"
