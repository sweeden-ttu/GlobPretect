"""
Blooming-directed-graph trigger process agent.
Triggers the appropriate process across languages, projects, repositories, clusters, and models.
Uses context_key (one of 20) or (language, project, repository, cluster, model) to decide action.
"""

import json
import os
import shlex
from typing import Any, Dict, Optional

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
_JSON_PATH = os.path.join(os.path.dirname(_SCRIPT_DIR), "blooming_directed_graph_filter_agents.json")

_spec: Optional[Dict[str, Any]] = None


def get_spec() -> Dict[str, Any]:
    global _spec
    if _spec is not None:
        return _spec
    with open(_JSON_PATH, encoding="utf-8") as f:
        data = json.load(f)
    _spec = data.get("blooming_directed_graph_trigger_process_agent") or {}
    return _spec


def resolve_context_key(
    context_key: Optional[str] = None,
    language: Optional[str] = None,
    project: Optional[str] = None,
    repository: Optional[str] = None,
    cluster: Optional[str] = None,
    model: Optional[str] = None,
) -> Optional[str]:
    if context_key and context_key.strip():
        return context_key
    if not cluster or not model:
        return None
    env = "owner_github"
    if "hpcc" in (cluster or "").lower():
        env = "owner_hpcc" if (project or "").lower().startswith("owner") else "quay_hpcc"
    elif "github" in (cluster or "").lower():
        env = "hpcc_github" if (project or "").lower().startswith("hpcc") else ("quay_github" if (project or "").lower().startswith("quay") else "owner_github")
    mod_map = {"granite": "granite", "deepseek": "deepseek", "qwen": "qwen", "codellama": "codellama"}
    mod = mod_map.get((model or "").lower(), "granite")
    return f"{env}_{mod}"


def action_for_key(context_key: Optional[str]) -> str:
    if not context_key:
        return "local"
    if "github" in context_key:
        return "github"
    if "hpcc" in context_key:
        return "hpcc"
    return "local"


def trigger(
    context_key: Optional[str] = None,
    language: Optional[str] = None,
    project: Optional[str] = None,
    repository: Optional[str] = None,
    cluster: Optional[str] = None,
    model: Optional[str] = None,
    projects_dir: Optional[str] = None,
) -> Dict[str, Any]:
    key = resolve_context_key(
        context_key=context_key,
        language=language,
        project=project,
        repository=repository,
        cluster=cluster,
        model=model,
    )
    action = action_for_key(key)
    projects_dir = projects_dir or os.environ.get("PROJECTS_DIR") or os.path.expanduser("~/projects")
    repo_root = os.path.dirname(os.path.dirname(_SCRIPT_DIR))
    scripts_dir = os.path.join(repo_root, "scripts")
    if action == "github":
        sync_script = os.path.join(scripts_dir, "daily-github-sync.sh")
        cmd = f"CONTEXT_KEY={shlex.quote(key or '')} PROJECTS_DIR={shlex.quote(projects_dir)} {shlex.quote(sync_script)} sync"
        return {"action": "github", "context_key": key, "command": cmd}
    if action == "hpcc":
        connect_script = os.path.join(scripts_dir, "connect-hpcc.sh")
        cmd = f"CONTEXT_KEY={shlex.quote(key or '')} {shlex.quote(connect_script)}"
        return {"action": "hpcc", "context_key": key, "command": cmd}
    if action == "local":
        return {"action": "local", "context_key": key, "command": None}
    return {"error": "Could not resolve context_key or action"}


if __name__ == "__main__":
    import sys
    key = (sys.argv[1] if len(sys.argv) > 1 else None) or os.environ.get("CONTEXT_KEY")
    result = trigger(context_key=key)
    print(json.dumps(result))
