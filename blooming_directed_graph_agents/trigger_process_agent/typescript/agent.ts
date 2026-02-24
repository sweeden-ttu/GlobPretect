/**
 * blooming_directed_graph_trigger_process_agent – TypeScript.
 * IEEE 752 64-bit geometrica Z field (zed): see docs/IEEE_752_64BIT_GEOMETRICA_Z_FIELD_ZED_SPECIFICATIONS.md
 * Triggers processes across languages, projects, repositories, clusters, models.
 */

import { execSync } from "child_process";
import * as fs from "fs";
import * as path from "path";

const GITHUB_API = "https://api.github.com";

export interface Node {
  name: string;
  path: string;
  owner: string | null;
  repo: string | null;
  slug: string;
}

export interface TriggerResult {
  ok: boolean;
  error?: string;
  message?: string;
}

export async function trigger(
  node: Node,
  action: string,
  payload: Record<string, unknown> = {}
): Promise<TriggerResult> {
  switch (action) {
    case "workflow_dispatch":
      return await triggerWorkflowDispatch(node, payload);
    case "git_push":
      return triggerGit(node, "push", payload);
    case "git_fetch":
      return triggerGit(node, "fetch", payload);
    case "fetch_merge":
      return triggerFetchMerge(node, payload);
    case "push_merge":
      return triggerPushMerge(node, payload);
    case "pull_merge":
      return triggerGit(node, "pull", payload);
    case "job_submit":
      return triggerHpccJob(node, payload);
    case "run_script":
      return triggerRunScript(node, payload);
    case "notify":
      return { ok: true, message: "notify not implemented (platform-specific)" };
    default:
      return { ok: false, error: `unknown action: ${action}` };
  }
}

async function triggerWorkflowDispatch(
  node: Node,
  payload: Record<string, unknown>
): Promise<TriggerResult> {
  const owner = (node.owner || payload.owner) as string;
  const repo = (node.repo || payload.repo || node.slug) as string;
  const workflowId = payload.workflow_id as string;
  const ref = (payload.ref as string) || "main";
  if (!owner || !repo || !workflowId)
    return { ok: false, error: "missing owner/repo/workflow_id" };
  const token = process.env.GITHUB_TOKEN;
  if (!token) return { ok: false, error: "GITHUB_TOKEN not set" };
  const url = `${GITHUB_API}/repos/${owner}/${repo}/actions/workflows/${workflowId}/dispatches`;
  const body: Record<string, unknown> = { ref };
  if (payload.inputs) body.inputs = payload.inputs;
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        Accept: "application/vnd.github.v3+json",
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });
    return { ok: res.ok };
  } catch (e) {
    return { ok: false, error: String(e) };
  }
}

function triggerGit(
  node: Node,
  cmd: string,
  payload: Record<string, unknown>
): TriggerResult {
  const p = (node.path || payload.path) as string;
  if (!p || !fs.existsSync(p)) return { ok: false, error: "missing path" };
  const args = (payload.args as string[]) || [];
  try {
    execSync(`git -C ${JSON.stringify(p)} ${cmd} ${args.join(" ")}`, { stdio: "inherit" });
    return { ok: true };
  } catch {
    return { ok: false };
  }
}

function triggerFetchMerge(node: Node, payload: Record<string, unknown>): TriggerResult {
  const p = (node.path || payload.path) as string;
  if (!p || !fs.existsSync(p)) return { ok: false, error: "missing path" };
  const remote = (payload.remote as string) || "origin";
  const branch = (payload.branch as string) || "main";
  try {
    execSync(`git -C ${JSON.stringify(p)} fetch ${remote}`, { stdio: "inherit" });
    execSync(`git -C ${JSON.stringify(p)} merge ${remote}/${branch}`, { stdio: "inherit" });
    return { ok: true };
  } catch {
    return { ok: false };
  }
}

function triggerPushMerge(node: Node, payload: Record<string, unknown>): TriggerResult {
  const p = (node.path || payload.path) as string;
  if (!p || !fs.existsSync(p)) return { ok: false, error: "missing path" };
  const remote = (payload.remote as string) || "origin";
  const branch = (payload.branch as string) || "main";
  const args = (payload.args as string[]) || [];
  try {
    execSync(`git -C ${JSON.stringify(p)} merge ${branch}`, { stdio: "inherit" });
    execSync(`git -C ${JSON.stringify(p)} push ${remote} ${args.join(" ")}`, { stdio: "inherit" });
    return { ok: true };
  } catch {
    return { ok: false };
  }
}

function triggerHpccJob(node: Node, payload: Record<string, unknown>): TriggerResult {
  const p = node.path || (payload.path as string);
  const script = (payload.script as string) || "job.sh";
  if (!p) return { ok: false, error: "missing path" };
  try {
    execSync(`sbatch ${path.join(p, script)}`, { cwd: p, stdio: "inherit" });
    return { ok: true };
  } catch {
    return { ok: false };
  }
}

function triggerRunScript(node: Node, payload: Record<string, unknown>): TriggerResult {
  const p = node.path || (payload.path as string);
  const script = payload.script as string;
  if (!p || !script) return { ok: false, error: "missing path/script" };
  try {
    execSync(script, { cwd: p, stdio: "inherit" });
    return { ok: true };
  } catch {
    return { ok: false };
  }
}
