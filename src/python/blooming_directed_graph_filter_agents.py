"""
Blooming-directed-graph filter agents collection.
Ten agents: ruby, typescript, python, csharp, java, bash, zsh, git, github, hpcc.
Each agent filters nodes/edges by its criteria (language, shell, vcs, or action_where).
"""

import json
import os
from typing import Any, Dict, List, Optional

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
_FILTER_AGENTS_JSON = os.path.join(os.path.dirname(_SCRIPT_DIR), "blooming_directed_graph_filter_agents.json")

_collection: Optional[List[Dict[str, Any]]] = None


def load_collection() -> List[Dict[str, Any]]:
    global _collection
    if _collection is not None:
        return _collection
    with open(_FILTER_AGENTS_JSON, encoding="utf-8") as f:
        data = json.load(f)
    _collection = data.get("blooming_directed_graph_filter_agents") or []
    return _collection


def by_id(agent_id: str) -> Optional[Dict[str, Any]]:
    for a in load_collection():
        if a.get("id") == agent_id:
            return a
    return None


def filter_nodes_for_agent(
    nodes: List[Dict[str, Any]],
    agent_id: str,
    context_key: Optional[str] = None,
) -> List[Dict[str, Any]]:
    agent = by_id(agent_id)
    if not agent:
        return nodes
    criteria = agent.get("filter_criteria") or {}
    action_where = criteria.get("action_where")
    if action_where and context_key:
        key_where = "github" if "github" in context_key else ("hpcc" if "hpcc" in context_key else None)
        return nodes if key_where == action_where else []
    return nodes


def agent_ids() -> List[str]:
    return [a["id"] for a in load_collection()]


if __name__ == "__main__":
    print("Filter agents:", ", ".join(agent_ids()))
    for a in load_collection():
        print(f"  {a['id']}: {a['name']} ({a['role']})")
