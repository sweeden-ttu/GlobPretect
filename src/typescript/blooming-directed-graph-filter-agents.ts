/**
 * Blooming-directed-graph filter agents collection.
 * Ten agents: ruby, typescript, python, csharp, java, bash, zsh, git, github, hpcc.
 */

import * as fs from "fs";
import * as path from "path";

const SCRIPT_DIR = __dirname;
const JSON_PATH = path.join(path.dirname(SCRIPT_DIR), "blooming_directed_graph_filter_agents.json");

export interface FilterAgent {
  id: string;
  name: string;
  role: string;
  filter_criteria?: Record<string, string>;
}

let collection: FilterAgent[] | null = null;

export function loadCollection(): FilterAgent[] {
  if (collection) return collection;
  const data = JSON.parse(fs.readFileSync(JSON_PATH, "utf8"));
  collection = data.blooming_directed_graph_filter_agents || [];
  return collection;
}

export function byId(agentId: string): FilterAgent | undefined {
  return loadCollection().find((a) => a.id === agentId);
}

export function filterNodesForAgent<T extends { name: string }>(
  nodes: T[],
  agentId: string,
  contextKey?: string | null
): T[] {
  const agent = byId(agentId);
  if (!agent) return nodes;
  const criteria = agent.filter_criteria || {};
  const actionWhere = criteria.action_where;
  if (actionWhere && contextKey) {
    const keyWhere = contextKey.includes("github") ? "github" : contextKey.includes("hpcc") ? "hpcc" : null;
    return keyWhere === actionWhere ? nodes : [];
  }
  return nodes;
}

export function agentIds(): string[] {
  return loadCollection().map((a) => a.id);
}

if (require.main === module) {
  console.log("Filter agents:", agentIds().join(", "));
  loadCollection().forEach((a) => console.log(`  ${a.id}: ${a.name} (${a.role})`));
}
