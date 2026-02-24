# blooming_directed_graph_filter_agents – Bash collection.
# Source this file, then call filter_by_receiver, filter_by_action_where, etc.
# Nodes/edges are passed as lines (e.g. node_name|path|owner|repo); filter_* output filtered lines.

filter_by_receiver() {
  local receiver="$1"
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    case "$receiver" in
      github|hpcc) [[ "$line" == *"|"*"|"*"|"* ]] && echo "$line" ;;
      *) echo "$line" ;;
    esac
  done
}

filter_by_action_where() {
  local where="$1"
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    case "$where" in
      github) [[ "$line" == *github* ]] && echo "$line" ;;
      hpcc)   [[ "$line" == *hpcc* ]] && echo "$line" ;;
      *) echo "$line" ;;
    esac
  done
}

filter_by_action_client() {
  local client="$1"
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    case "$client" in
      macbook)     [[ "$line" == *owner* ]] && echo "$line" ;;
      rockydesktop) [[ "$line" == *quay* ]] && echo "$line" ;;
      *) echo "$line" ;;
    esac
  done
}

filter_by_repo_name() {
  local pattern="$1"
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local name="${line%%|*}"
    [[ "$name" == *"$pattern"* ]] && echo "$line"
  done
}
