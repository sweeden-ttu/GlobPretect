#!/usr/bin/env bash
# blooming_directed_graph_trigger_process_agent – Bash.
# IEEE 752 64-bit geometrica Z field (zed): see docs/IEEE_752_64BIT_GEOMETRICA_Z_FIELD_ZED_SPECIFICATIONS.md
# Usage: trigger_process_agent.sh <node_path> <action> [key=val ...]
# Actions: workflow_dispatch, git_push, git_fetch, fetch_merge, push_merge, pull_merge, job_submit, run_script, notify

set -e
NODE_PATH="${1:?}"
ACTION="${2:?}"
shift 2 || true

# Parse key=val into env
while [[ $# -gt 0 ]]; do
  case "$1" in
    *=*) export "${1%%=*}=${1#*=}" ;;
  esac
  shift
done

case "$ACTION" in
  workflow_dispatch)
    owner="${owner:-}"
    repo="${repo:-}"
    workflow_id="${workflow_id:-}"
    ref="${ref:-main}"
    if [[ -z "$owner" || -z "$repo" || -z "$workflow_id" ]]; then
      echo '{"ok":false,"error":"missing owner/repo/workflow_id"}' && exit 1
    fi
    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
      echo '{"ok":false,"error":"GITHUB_TOKEN not set"}' && exit 1
    fi
    curl -sS -X POST \
      -H "Accept: application/vnd.github.v3+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"ref\":\"$ref\"}" \
      "https://api.github.com/repos/$owner/$repo/actions/workflows/$workflow_id/dispatches"
    echo '{"ok":true}'
    ;;
  git_push)
    (cd "$NODE_PATH" && git push "$@") && echo '{"ok":true}' || echo '{"ok":false}'
    ;;
  git_fetch)
    (cd "$NODE_PATH" && git fetch "$@") && echo '{"ok":true}' || echo '{"ok":false}'
    ;;
  fetch_merge)
    remote="${remote:-origin}"
    branch="${branch:-main}"
    (cd "$NODE_PATH" && git fetch "$remote" && git merge "$remote/$branch") && echo '{"ok":true}' || echo '{"ok":false}'
    ;;
  push_merge)
    remote="${remote:-origin}"
    branch="${branch:-main}"
    (cd "$NODE_PATH" && git merge "$branch" 2>/dev/null; git push "$remote" "$@") && echo '{"ok":true}' || echo '{"ok":false}'
    ;;
  pull_merge)
    remote="${remote:-origin}"
    branch="${branch:-main}"
    (cd "$NODE_PATH" && git pull "$remote" "$branch" "$@") && echo '{"ok":true}' || echo '{"ok":false}'
    ;;
  job_submit)
    script="${script:-job.sh}"
    (cd "$NODE_PATH" && sbatch "$script") && echo '{"ok":true}' || echo '{"ok":false}'
    ;;
  run_script)
    script="${script:-}"
    [[ -z "$script" ]] && echo '{"ok":false,"error":"missing script"}' && exit 1
    (cd "$NODE_PATH" && eval "$script") && echo '{"ok":true}' || echo '{"ok":false}'
    ;;
  notify)
    echo '{"ok":true,"message":"notify not implemented"}'
    ;;
  *)
    echo "{\"ok\":false,\"error\":\"unknown action: $ACTION\"}" && exit 1
    ;;
esac
