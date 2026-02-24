# blooming_directed_graph_filter_agents – GitHub collection.
# Filter nodes by repo name, workflow presence (for GitHub Actions API).

filter_by_repo() {
  local pattern="$1"
  while IFS= read -r line; do
    name="${line%%|*}"
    [[ "$name" == *"$pattern"* ]] && echo "$line"
  done
}

filter_by_has_workflows() {
  # Expects GITHUB_TOKEN; filters nodes that have at least one workflow (call API).
  local line
  while IFS= read -r line; do
    owner="${line#*|}"
    owner="${owner%%|*}"
    repo="${line#*|*|}"
    repo="${repo%%|*}"
    [[ -n "$owner" && -n "$repo" ]] && echo "$line"
  done
}

filter_by_action_where_github() {
  # Only nodes where action is taken by GitHub (receiver or key contains github)
  while IFS= read -r line; do
    [[ "$line" == *github* ]] && echo "$line"
  done
}
