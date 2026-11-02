#!/usr/bin/env bash
# Wait for the GitHub Actions runs of one commit and print their results.
# Usage: ci-wait.sh [--timeout <minutes>] [--grace <seconds>]
#                   [--interval <seconds>] [--repo <owner/name>] [<commit>]
# Defaults: 60 minutes, 120 seconds, 30 seconds, the local repo, and HEAD.
# The grace period limits the wait for the first run.
# A complete list must then stay unchanged for that period.
# Completion needs two equal complete polls and the grace period or deadline.
# With --repo, supply a full commit SHA. Requires gh, but does not need jq.
# Exits: 0 passed, 1 failed, 2 pending at deadline, 3 no run, 4 usage/tool error.
set -euo pipefail

usage() {
  echo "ci-wait.sh [--timeout <minutes>] [--grace <seconds>] [--interval <seconds>]"
  echo "           [--repo <owner/name>] [<commit>]"
}

usage_error() { echo "$*" >&2; usage >&2; exit 4; }

timeout=60
grace=120
interval=30
repo=""
commit=HEAD
commit_given=0
while (( $# > 0 )); do
  case "$1" in
    --timeout|--grace|--interval|--repo)
      (( $# >= 2 )) || usage_error "missing value for $1"
      [[ -n "$2" ]] || usage_error "missing value for $1"
      case "$1" in
        --timeout) timeout="$2" ;;
        --grace) grace="$2" ;;
        --interval) interval="$2" ;;
        --repo) repo="$2" ;;
      esac
      shift 2
      ;;
    --help|-h) usage; exit 0 ;;
    --) shift; break ;;
    -*) usage_error "unknown option: $1" ;;
    *)
      (( commit_given == 0 )) || usage_error "give only one commit"
      commit="$1"
      commit_given=1
      shift
      ;;
  esac
done
if (( $# > 0 )); then
  (( $# == 1 && commit_given == 0 )) || usage_error "give only one commit"
  commit="$1"
  commit_given=1
fi
for value in "$timeout" "$grace" "$interval"; do
  case "$value" in
    *[!0-9]*|'') usage_error "time values must be non-negative integers" ;;
  esac
done
timeout=$((10#$timeout))
grace=$((10#$grace))
interval=$((10#$interval))
command -v gh >/dev/null 2>&1 || usage_error "gh is not installed"
if [[ -n "$repo" ]]; then
  [[ "$commit_given" == 1 && "$commit" =~ ^[[:xdigit:]]{40}$ ]] \
    || usage_error "with --repo, give a full commit SHA"
  sha="$commit"
else
  sha="$(git rev-parse --verify "${commit}^{commit}")" || usage_error "cannot resolve commit: $commit"
fi

now="$(date +%s)"
deadline=$((now + timeout * 60))
grace_deadline=$((now + grace))
stable_since="$now"
failures=0
response=""
runs=""
previous=""
complete=1

# Keep the response and consecutive failure count in this shell.
gh_query() {
  if [[ -n "$repo" ]]; then set -- -R "$repo" "$@"; fi
  if response="$(gh "$@" < /dev/null)"; then
    failures=0
    return 0
  fi
  failures=$((failures + 1))
  printf 'warning: gh call failed (%s/3)\n' "$failures" >&2
  if (( failures >= 3 )); then
    echo "three failed gh calls in a row" >&2
    exit 4
  fi
  return 1
}

pause_poll() {
  local delay="$interval" remaining
  if [[ -z "$runs" ]]; then
    remaining=$((grace_deadline - now))
  else
    remaining=$((deadline - now))
  fi
  if (( delay > remaining )); then delay="$remaining"; fi
  if (( delay > 0 )); then sleep "$delay"; fi
}

report_runs() {
  local id status conclusion workflow url result=0
  while IFS=$'\t' read -r id status conclusion workflow url; do
    [[ -n "$id" ]] || continue
    if [[ "$status" != completed ]]; then
      printf '%s %s %s\n' "$status" "$workflow" "$url"
      continue
    fi
    printf '%s %s %s\n' "$conclusion" "$workflow" "$url"
    case "$conclusion" in success|skipped|neutral) continue ;; esac
    result=1
    while ! gh_query run view "$id" --json jobs --jq '
      .jobs[] | select(.conclusion == "failure") |
      "  \(.name): \([.steps[]? | select(.conclusion == "failure") | .name][0] // "no failed step")"
    '; do pause_poll; done
    if [[ -n "$response" ]]; then printf '%s\n' "$response"; fi
  done <<< "$runs"
  return "$result"
}

while :; do
  if gh_query run list --commit "$sha" --limit 100 \
    --json databaseId,workflowName,status,conclusion,url --jq '
      sort_by(.databaseId)[] |
      [.databaseId, .status,
       (if (.conclusion // "") == "" then "-" else .conclusion end),
       .workflowName, .url] | @tsv
    '; then
    now="$(date +%s)"
    runs="$response"
    if [[ "$runs" != "$previous" ]]; then stable_since="$now"; fi
    if [[ -z "$runs" ]]; then
      previous=""
      if (( now >= grace_deadline )); then
        echo "no CI run for $sha"
        exit 3
      fi
    else
      complete=1
      while IFS=$'\t' read -r id status rest; do
        if [[ "$status" != completed ]]; then complete=0; fi
      done <<< "$runs"
      if (( complete )); then
        if [[ "$runs" == "$previous" ]] && (( now - stable_since >= grace || now >= deadline )); then
          result=0
          report_runs || result=$?
          exit "$result"
        fi
      fi
      previous="$runs"
    fi
  else
    now="$(date +%s)"
    previous=""
  fi
  if [[ -n "$runs" ]] && (( complete == 0 && now >= deadline )); then
    report_runs || true
    echo "CI pending at deadline for $sha" >&2
    exit 2
  fi
  pause_poll
done
