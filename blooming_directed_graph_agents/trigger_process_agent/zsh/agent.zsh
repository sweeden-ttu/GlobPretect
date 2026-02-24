#!/usr/bin/env zsh
# blooming_directed_graph_trigger_process_agent – Zsh. IEEE 752 64-bit geometrica Z field (zed): see docs/IEEE_752_64BIT_GEOMETRICA_Z_FIELD_ZED_SPECIFICATIONS.md
# Same as Bash agent; delegate to bash or run natively.
SCRIPT_DIR="${0:A:h}"
bash "$SCRIPT_DIR/../bash/agent.sh" "$@" 2>/dev/null || {
  # Inline fallback
  NODE_PATH="${1:?}"
  ACTION="${2:?}"
  shift 2
  case "$ACTION" in
    git_push)   (cd "$NODE_PATH" && git push "$@") && echo '{"ok":true}' || echo '{"ok":false}' ;;
    git_fetch)  (cd "$NODE_PATH" && git fetch "$@") && echo '{"ok":true}' || echo '{"ok":false}' ;;
    fetch_merge)  (cd "$NODE_PATH" && git fetch "${remote:-origin}" && git merge "${remote:-origin}/${branch:-main}") && echo '{"ok":true}' || echo '{"ok":false}' ;;
    push_merge)   (cd "$NODE_PATH" && git merge "${branch:-main}" 2>/dev/null; git push "${remote:-origin}" "$@") && echo '{"ok":true}' || echo '{"ok":false}' ;;
    pull_merge)   (cd "$NODE_PATH" && git pull "${remote:-origin}" "${branch:-main}" "$@") && echo '{"ok":true}' || echo '{"ok":false}' ;;
    notify)     echo '{"ok":true,"message":"notify not implemented"}' ;;
    *)          echo "{\"ok\":false,\"error\":\"unknown action: $ACTION\"}" ; exit 1 ;;
  esac
}
