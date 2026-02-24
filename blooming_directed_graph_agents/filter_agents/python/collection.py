"""
blooming_directed_graph_filter_agents – Python collection.
Filter nodes/edges by receiver, action_where, action_client, repo name.
Nodes are dicts: name, path, owner, repo, slug.
"""

from typing import List, Dict, Any, Optional, Union
import re


def filter_by_receiver(nodes: List[Dict[str, Any]], receiver: str) -> List[Dict[str, Any]]:
    if receiver not in ("github", "hpcc"):
        return nodes
    return [n for n in nodes if n.get("owner") and n.get("repo")]


def filter_by_action_where(nodes: List[Dict[str, Any]], where: str) -> List[Dict[str, Any]]:
    if where not in ("github", "hpcc"):
        return nodes
    return [
        n for n in nodes
        if (where == "github" and "github" in (n.get("name") or "")) or
           (where == "hpcc" and "hpcc" in (n.get("name") or "").lower())
    ]


def filter_by_action_client(
    nodes: List[Dict[str, Any]], client: str
) -> List[Dict[str, Any]]:
    if client not in ("macbook", "rockydesktop"):
        return nodes
    return [
        n for n in nodes
        if (client == "macbook" and ("owner" in (n.get("name") or ""))) or
           (client == "rockydesktop" and ("quay" in (n.get("name") or "")))
    ]


def filter_by_repo_name(
    nodes: List[Dict[str, Any]], pattern: Union[str, re.Pattern]
) -> List[Dict[str, Any]]:
    if isinstance(pattern, str):
        pattern = re.compile(re.escape(pattern))
    return [n for n in nodes if pattern.search(n.get("name") or "")]
