# blooming_directed_graph_filter_agents – HPCC collection.
# Filter nodes by partition, cluster, job (for HPCC/Slurm).

filter_by_partition() {
  local partition="$1"
  # Nodes that are HPCC-related (path or name contains hpcc)
  while IFS= read -r line; do
    name="${line%%|*}"
    path="${line#*|}"
    [[ "$name" == *hpcc* || "$path" == *hpcc* ]] && echo "$line"
  done
}

filter_by_action_where_hpcc() {
  while IFS= read -r line; do
    [[ "$line" == *hpcc* ]] && echo "$line"
  done
}

filter_by_repo_name() {
  local pattern="$1"
  while IFS= read -r line; do
    name="${line%%|*}"
    [[ "$name" == *"$pattern"* ]] && echo "$line"
  done
}
