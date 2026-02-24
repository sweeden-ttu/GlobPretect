#!/usr/bin/env bash
# blooming_directed_graph_trigger_process_agent – GitHub. IEEE 752 64-bit geometrica Z field (zed): see docs/IEEE_752_64BIT_GEOMETRICA_Z_FIELD_ZED_SPECIFICATIONS.md
# Triggers workflow_dispatch via API; supports fetch_merge, push_merge, pull_merge in repo path.
# Usage (workflow): agent.sh <owner> <repo> <workflow_id> [ref=main]
# Usage (fetch_merge/push_merge/pull_merge): agent.sh <node_path> fetch_merge|push_merge|pull_merge [remote=origin] [branch=main]
set -e
ARG1="${1:?}"
ARG2="${2:?}"
if [[ -d "$ARG1" ]] && [[ "$ARG2" == "fetch_merge" || "$ARG2" == "push_merge" || "$ARG2" == "pull_merge" ]]; then
  NODE_PATH="$ARG1"
  ACTION="$ARG2"
  remote="${remote:-origin}"
  branch="${branch:-main}"
  shift 2
  case "$ACTION" in
    fetch_merge) (cd "$NODE_PATH" && git fetch "$remote" && git merge "$remote/$branch") && echo '{"ok":true}' || echo '{"ok":false}' ;;
    push_merge)  (cd "$NODE_PATH" && git merge "$branch" 2>/dev/null; git push "$remote" "$@") && echo '{"ok":true}' || echo '{"ok":false}' ;;
    pull_merge)  (cd "$NODE_PATH" && git pull "$remote" "$branch" "$@") && echo '{"ok":true}' || echo '{"ok":false}' ;;
  esac
  exit 0
fi
OWNER="$ARG1"
REPO="$ARG2"
WORKFLOW_ID="${3:?}"
REF="${4:-main}"
[[ -z "$GITHUB_TOKEN" ]] && echo '{"ok":false,"error":"GITHUB_TOKEN not set"}' && exit 1
curl -sS -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"ref\":\"$REF\"}" \
  "https://api.github.com/repos/$OWNER/$REPO/actions/workflows/$WORKFLOW_ID/dispatches"
echo '{"ok":true}'
