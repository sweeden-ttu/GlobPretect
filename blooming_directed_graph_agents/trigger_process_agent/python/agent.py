"""
blooming_directed_graph_trigger_process_agent – Python.
IEEE 752 64-bit geometrica Z field (zed): see docs/IEEE_752_64BIT_GEOMETRICA_Z_FIELD_ZED_SPECIFICATIONS.md
Triggers processes across languages, projects, repositories, clusters, models.
Action types: workflow_dispatch, job_submit, git_push, git_fetch, fetch_merge, push_merge, pull_merge, run_script, notify.
"""

import os
import json
import subprocess
import urllib.request
import urllib.error
from typing import Dict, Any, Optional


GITHUB_API = "https://api.github.com"


def trigger(node: Dict[str, Any], action: str, payload: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    payload = payload or {}
    if action == "workflow_dispatch":
        return _trigger_workflow_dispatch(node, payload)
    if action == "git_push":
        return _trigger_git(node, "push", payload)
    if action == "git_fetch":
        return _trigger_git(node, "fetch", payload)
    if action == "fetch_merge":
        return _trigger_fetch_merge(node, payload)
    if action == "push_merge":
        return _trigger_push_merge(node, payload)
    if action == "pull_merge":
        return _trigger_git(node, "pull", payload)
    if action == "job_submit":
        return _trigger_hpcc_job(node, payload)
    if action == "run_script":
        return _trigger_run_script(node, payload)
    if action == "notify":
        return {"ok": True, "message": "notify not implemented (platform-specific)"}
    return {"ok": False, "error": f"unknown action: {action}"}


def _trigger_workflow_dispatch(node: Dict[str, Any], payload: Dict[str, Any]) -> Dict[str, Any]:
    owner = node.get("owner") or payload.get("owner")
    repo = node.get("repo") or payload.get("repo") or node.get("slug")
    workflow_id = payload.get("workflow_id")
    ref = payload.get("ref", "main")
    if not owner or not repo or not workflow_id:
        return {"ok": False, "error": "missing owner/repo/workflow_id"}
    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        return {"ok": False, "error": "GITHUB_TOKEN not set"}
    url = f"{GITHUB_API}/repos/{owner}/{repo}/actions/workflows/{workflow_id}/dispatches"
    body = {"ref": ref}
    if payload.get("inputs"):
        body["inputs"] = payload["inputs"]
    req = urllib.request.Request(url, data=json.dumps(body).encode(), method="POST")
    req.add_header("Accept", "application/vnd.github.v3+json")
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return {"ok": resp.status < 400}
    except urllib.error.HTTPError as e:
        return {"ok": False, "error": f"HTTP {e.code}"}
    except Exception as e:
        return {"ok": False, "error": str(e)}


def _trigger_git(node: Dict[str, Any], cmd: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    path = node.get("path") or payload.get("path")
    if not path or not os.path.isdir(path):
        return {"ok": False, "error": "missing path"}
    args = payload.get("args") or []
    r = subprocess.run(["git", "-C", path, cmd] + list(args), capture_output=True)
    return {"ok": r.returncode == 0}


def _trigger_fetch_merge(node: Dict[str, Any], payload: Dict[str, Any]) -> Dict[str, Any]:
    path = node.get("path") or payload.get("path")
    if not path or not os.path.isdir(path):
        return {"ok": False, "error": "missing path"}
    remote = payload.get("remote", "origin")
    branch = payload.get("branch", "main")
    r1 = subprocess.run(["git", "-C", path, "fetch", remote], capture_output=True)
    if r1.returncode != 0:
        return {"ok": False}
    r2 = subprocess.run(["git", "-C", path, "merge", f"{remote}/{branch}"], capture_output=True)
    return {"ok": r2.returncode == 0}


def _trigger_push_merge(node: Dict[str, Any], payload: Dict[str, Any]) -> Dict[str, Any]:
    path = node.get("path") or payload.get("path")
    if not path or not os.path.isdir(path):
        return {"ok": False, "error": "missing path"}
    remote = payload.get("remote", "origin")
    branch = payload.get("branch", "main")
    subprocess.run(["git", "-C", path, "merge", branch], capture_output=True)
    args = payload.get("args") or []
    r = subprocess.run(["git", "-C", path, "push", remote] + list(args), capture_output=True)
    return {"ok": r.returncode == 0}


def _trigger_hpcc_job(node: Dict[str, Any], payload: Dict[str, Any]) -> Dict[str, Any]:
    path = node.get("path") or payload.get("path")
    script = payload.get("script", "job.sh")
    if not path:
        return {"ok": False, "error": "missing path"}
    r = subprocess.run(["sbatch", os.path.join(path, script)], cwd=path, capture_output=True)
    return {"ok": r.returncode == 0}


def _trigger_run_script(node: Dict[str, Any], payload: Dict[str, Any]) -> Dict[str, Any]:
    path = node.get("path") or payload.get("path")
    script = payload.get("script")
    if not path or not script:
        return {"ok": False, "error": "missing path/script"}
    r = subprocess.run(script, shell=True, cwd=path)
    return {"ok": r.returncode == 0}
