#!/usr/bin/env bash
# blooming_directed_graph_trigger_process_agent – Git. IEEE 752 64-bit geometrica Z field (zed): see docs/IEEE_752_64BIT_GEOMETRICA_Z_FIELD_ZED_SPECIFICATIONS.md
# Usage: agent.sh <node_path> <action> [args...]
set -e
NODE_PATH="${1:?}"
ACTION="${2:?}"
shift 2 || true
remote="${remote:-origin}"
branch="${branch:-main}"
case "$ACTION" in
  git_push)    (cd "$NODE_PATH" && git push "$@") ;;
  git_fetch)   (cd "$NODE_PATH" && git fetch "$@") ;;
  git_merge)   (cd "$NODE_PATH" && git merge "$@") ;;
  fetch_merge) (cd "$NODE_PATH" && git fetch "$remote" && git merge "$remote/$branch") ;;
  push_merge)   (cd "$NODE_PATH" && git merge "$branch" 2>/dev/null; git push "$remote" "$@") ;;
  pull_merge)   (cd "$NODE_PATH" && git pull "$remote" "$branch" "$@") ;;
  *) echo "Unknown action: $ACTION" >&2 ; exit 1 ;;
esac
echo '{"ok":true}'
