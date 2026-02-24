/**
 * blooming_directed_graph_filter_agents – TypeScript collection.
 * Filter nodes/edges by receiver, action_where, action_client, repo name.
 */

export interface Node {
  name: string;
  path: string;
  owner: string | null;
  repo: string | null;
  slug: string;
}

export function filterByReceiver(nodes: Node[], receiver: string): Node[] {
  if (receiver !== "github" && receiver !== "hpcc") return nodes;
  return nodes.filter((n) => n.owner && n.repo);
}

export function filterByActionWhere(nodes: Node[], where: string): Node[] {
  if (where !== "github" && where !== "hpcc") return nodes;
  return nodes.filter((n) =>
    where === "github" ? n.name.includes("github") : n.name.toLowerCase().includes("hpcc")
  );
}

export function filterByActionClient(nodes: Node[], client: string): Node[] {
  if (client !== "macbook" && client !== "rockydesktop") return nodes;
  return nodes.filter((n) =>
    client === "macbook" ? n.name.includes("owner") : n.name.includes("quay")
  );
}

export function filterByRepoName(nodes: Node[], pattern: string | RegExp): Node[] {
  const re = typeof pattern === "string" ? new RegExp(escapeRe(pattern)) : pattern;
  return nodes.filter((n) => re.test(n.name));
}

function escapeRe(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
