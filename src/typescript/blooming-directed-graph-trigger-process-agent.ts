/**
 * Blooming-directed-graph trigger process agent.
 * Triggers the appropriate process across languages, projects, repositories, clusters, and models.
 */

import * as fs from "fs";
import * as path from "path";

const SCRIPT_DIR = __dirname;
const JSON_PATH = path.join(path.dirname(SCRIPT_DIR), "blooming_directed_graph_filter_agents.json");

interface TriggerSpec {
  id: string;
  name: string;
  description?: string;
  inputs?: string[];
  actions?: Record<string, string>;
}

let spec: TriggerSpec | null = null;

function getSpec(): TriggerSpec {
  if (spec) return spec;
  const data = JSON.parse(fs.readFileSync(JSON_PATH, "utf8"));
  spec = data.blooming_directed_graph_trigger_process_agent || {};
  return spec;
}

export function resolveContextKey(params: {
  context_key?: string | null;
  language?: string | null;
  project?: string | null;
  repository?: string | null;
  cluster?: string | null;
  model?: string | null;
}): string | null {
  const { context_key, project, cluster, model } = params;
  if (context_key && context_key.trim()) return context_key;
  if (!cluster || !model) return null;
  let env = "owner_github";
  if (String(cluster).toLowerCase().includes("hpcc")) {
    env = String(project).toLowerCase().startsWith("owner") ? "owner_hpcc" : "quay_hpcc";
  } else if (String(cluster).toLowerCase().includes("github")) {
    env = String(project).toLowerCase().startsWith("hpcc") ? "hpcc_github" : String(project).toLowerCase().startsWith("quay") ? "quay_github" : "owner_github";
  }
  const modMap: Record<string, string> = { granite: "granite", deepseek: "deepseek", qwen: "qwen", codellama: "codellama" };
  const mod = modMap[String(model).toLowerCase()] || "granite";
  return `${env}_${mod}`;
}

export function actionForKey(contextKey: string | null | undefined): "github" | "hpcc" | "local" {
  if (!contextKey) return "local";
  if (contextKey.includes("github")) return "github";
  if (contextKey.includes("hpcc")) return "hpcc";
  return "local";
}

export interface TriggerResult {
  action?: string;
  context_key?: string | null;
  command?: string | null;
  error?: string;
}

export function trigger(params: {
  context_key?: string | null;
  language?: string | null;
  project?: string | null;
  repository?: string | null;
  cluster?: string | null;
  model?: string | null;
  projects_dir?: string | null;
}): TriggerResult {
  const key = resolveContextKey(params);
  const action = actionForKey(key);
  const projectsDir = params.projects_dir || process.env.PROJECTS_DIR || path.join(process.env.HOME || "", "projects");
  const repoRoot = path.dirname(path.dirname(SCRIPT_DIR));
  const scriptsDir = path.join(repoRoot, "scripts");
  const quote = (s: string) => (s.includes(" ") || s.includes("'") ? `"${s.replace(/"/g, '\\"')}"` : s);
  if (action === "github") {
    const syncScript = path.join(scriptsDir, "daily-github-sync.sh");
    const cmd = `CONTEXT_KEY=${quote(key || "")} PROJECTS_DIR=${quote(projectsDir)} ${quote(syncScript)} sync`;
    return { action: "github", context_key: key, command: cmd };
  }
  if (action === "hpcc") {
    const connectScript = path.join(scriptsDir, "connect-hpcc.sh");
    const cmd = `CONTEXT_KEY=${quote(key || "")} ${quote(connectScript)}`;
    return { action: "hpcc", context_key: key, command: cmd };
  }
  if (action === "local") {
    return { action: "local", context_key: key, command: null };
  }
  return { error: "Could not resolve context_key or action" };
}

if (require.main === module) {
  const key = process.argv[2] || process.env.CONTEXT_KEY;
  const result = trigger({ context_key: key });
  console.log(JSON.stringify(result));
}
