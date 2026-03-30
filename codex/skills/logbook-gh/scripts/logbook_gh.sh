#!/usr/bin/env bash
set -euo pipefail

# Ensure a required command exists.
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

# Normalize a repository input into owner/repo form.
normalize_repo() {
  local input="${1:-}"

  if [[ -z "$input" ]] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    input="$(git remote get-url origin 2>/dev/null || true)"
  fi

  if [[ -z "$input" ]]; then
    echo "Could not determine repository. Please provide owner/repo or a GitHub URL." >&2
    exit 1
  fi

  input="${input%.git}"
  input="${input#https://github.com/}"
  input="${input#http://github.com/}"
  input="${input#git@github.com:}"

  if [[ "$input" =~ ^[^/]+/[^/]+$ ]]; then
    echo "$input"
    return
  fi

  echo "Unsupported repository format: $input" >&2
  exit 1
}

# Print one markdown section from a GitHub PR search command.
format_section() {
  local title="$1"
  shift

  echo "## $title"

  local json
  json="$(gh search prs \
    --repo "$REPO" \
    --limit 100 \
    --json number,title,url,updatedAt \
    "$@")"

  if [[ "$(echo "$json" | jq 'length')" -eq 0 ]]; then
    echo "- None"
    echo
    return
  fi

  echo "$json" | jq -r '
    sort_by(.updatedAt) | reverse | unique_by(.number) |
    .[] | "- \(.title) [(#\(.number))](\(.url))"
  '

  echo
}

require_cmd gh
require_cmd jq

REPO="$(normalize_repo "${1:-}")"
DATE="${2:-}"   # expected format: YYYY-MM-DD
LOGIN="${GITHUB_LOGIN:-$(gh api user -q .login)}"

if [[ -n "$DATE" ]]; then
  format_section "Merged PRs" \
    --author "$LOGIN" \
    --merged \
    --merged-at ">=$DATE"

  format_section "Open PRs" \
    --author "$LOGIN" \
    --state open \
    --created ">=$DATE"

  format_section "Reviews" \
    --reviewed-by "$LOGIN" \
    --updated ">=$DATE"
else
  format_section "Merged PRs" \
    --author "$LOGIN" \
    --merged

  format_section "Open PRs" \
    --author "$LOGIN" \
    --state open

  format_section "Reviews" \
    --reviewed-by "$LOGIN"
fi
