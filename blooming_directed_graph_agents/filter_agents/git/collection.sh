# blooming_directed_graph_filter_agents – Git collection.
# Filter nodes by git remote, branch, repo name (for git operations).

filter_by_remote() {
  local remote="$1"
  local nodes_file="${2:-}"
  # If nodes_file given, each line is node_path; else stdin
  if [[ -n "$nodes_file" ]]; then
    while IFS= read -r path < "$nodes_file"; do
      (cd "$path" 2>/dev/null && git remote get-url "$remote" 2>/dev/null) && echo "$path"
    done
  else
    while IFS= read -r line; do
      path="${line%%|*}"
      path="${path#*|}"
      [[ -d "$path/.git" ]] && (cd "$path" && git remote get-url "$remote" 2>/dev/null) && echo "$line"
    done
  fi
}

filter_by_branch() {
  local branch="$1"
  while IFS= read -r line; do
    path="${line#*|}"
    path="${path%%|*}"
    [[ -d "$path/.git" ]] && (cd "$path" && git branch --show-current 2>/dev/null) | grep -q "^${branch}$" && echo "$line"
  done
}

filter_by_repo_name() {
  local pattern="$1"
  while IFS= read -r line; do
    name="${line%%|*}"
    [[ "$name" == *"$pattern"* ]] && echo "$line"
  done
}
