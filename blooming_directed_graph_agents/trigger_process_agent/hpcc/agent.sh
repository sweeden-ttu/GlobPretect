#!/usr/bin/env bash
# blooming_directed_graph_trigger_process_agent – HPCC. IEEE 752 64-bit geometrica Z field (zed): see docs/IEEE_752_64BIT_GEOMETRICA_Z_FIELD_ZED_SPECIFICATIONS.md
# Submits Slurm job (sbatch); supports fetch_merge, push_merge, pull_merge in repo path.
# Usage: agent.sh <node_path> job_submit|fetch_merge|push_merge|pull_merge [script=job.sh or remote=origin branch=main]
set -e
NODE_PATH="${1:?}"
ACTION="${2:-job_submit}"
SCRIPT="${3:-job.sh}"
remote="${remote:-origin}"
branch="${branch:-main}"
case "$ACTION" in
  job_submit)
    (cd "$NODE_PATH" && sbatch "$SCRIPT") && echo '{"ok":true}' || echo '{"ok":false}'
    ;;
  fetch_merge)
    (cd "$NODE_PATH" && git fetch "$remote" && git merge "$remote/$branch") && echo '{"ok":true}' || echo '{"ok":false}'
    ;;
  push_merge)
    (cd "$NODE_PATH" && git merge "$branch" 2>/dev/null; git push "$remote") && echo '{"ok":true}' || echo '{"ok":false}'
    ;;
  pull_merge)
    (cd "$NODE_PATH" && git pull "$remote" "$branch") && echo '{"ok":true}' || echo '{"ok":false}'
    ;;
  *)
    echo '{"ok":false,"error":"unknown action: '"$ACTION"'"}' && exit 1
    ;;
esac
