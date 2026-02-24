# Blooming-directed-graph agents: filter agents and trigger process agent

Agents operate on the **blooming-directed-graph** (nodes = repos, directed edges to github_actions). They run across **all languages, projects, repositories, clusters, and models** (20 context keys).

## 1. blooming_directed_graph_filter_agents (collections)

**Filter agents** take the graph (nodes + edges) and optional parameters, and return a filtered subset. One **collection** per platform:

| Platform     | Role |
|-------------|------|
| **swift**   | Filter by receiver, action_where, repo name (iOS/macOS apps). |
| **objective-c** | Same (legacy macOS/iOS). |
| **ruby**    | Filter in Ruby scripts (e.g. daily-github-sync, tooling). |
| **typescript** | Filter in Node/TS (CI, web, tooling). |
| **python**  | Filter in Python (automation, HPCC jobs). |
| **csharp**  | Filter in .NET (Windows, cross-plat). |
| **java**    | Filter in JVM (services, Android). |
| **bash**    | Filter in shell (scripts, cron). |
| **zsh**     | Filter in zsh (interactive, scripts). |
| **git**     | Filter by remote, branch, repo (git operations). |
| **github**  | Filter by repo, workflow, run (GitHub Actions API). |
| **hpcc**    | Filter by partition, job, cluster (HPCC/Slurm). |

**Common filter semantics (all platforms):**

- `filter_by_receiver(nodes, "github" | "hpcc")` – nodes whose receiver matches.
- `filter_by_action_where(nodes, "github" | "hpcc")` – nodes where CONTEXT_ACTION_WHERE matches.
- `filter_by_action_client(nodes, "macbook" | "rockydesktop")` – nodes for that local client.
- `filter_by_repo_name(nodes, pattern)` – nodes whose name matches.
- `filter_by_context_key(nodes, key)` – node for that context key (if repo maps to key).

Implementations live under: `blooming_directed_graph_agents/filter_agents/<platform>/`.

## 2. blooming_directed_graph_trigger_process_agent

**Trigger process agent** takes a **node** (or filtered set), an **action type**, and optional **payload**, and triggers a process across:

- **Languages**: swift, objective-c, ruby, typescript, python, csharp, java, bash, zsh
- **Projects**: all under PROJECTS_DIR
- **Repositories**: each repo as graph node
- **Clusters**: HPCC (login, gpu, cpu), local (macbook, rockydesktop)
- **Models**: @granite, @deepseek, @qwen, @codellama (from 20 context keys)

**Action types:**

- `workflow_dispatch` – trigger GitHub Actions workflow for repo.
- `job_submit` – submit HPCC/Slurm job (cluster).
- `git_push` / `git_fetch` – run git command in repo.
- **`fetch_merge`** – git fetch then git merge (payload: `remote`, `branch`; default origin, main). Defined in all 4 environments (granite, deepseek, qwen, codellama).
- **`push_merge`** – optional merge then git push (payload: `remote`, `branch`; merge branch into current then push). Defined in all 4 environments.
- **`pull_merge`** – git pull (fetch + merge). Defined in all 4 environments.
- `run_script` – run a script in repo (by language/platform).
- `notify` – notify by platform (e.g. macbook, rockydesktop).

One trigger process agent implementation per platform; each can delegate to GitHub, HPCC, or git as needed. Implementations: `blooming_directed_graph_agents/trigger_process_agent/<platform>/`.

## 3. File layout (canonical)

```
blooming_directed_graph_agents/
  README.md
  filter_agents/
    swift/Collection.swift
    objective-c/Collection.h, Collection.m
    ruby/collection.rb
    typescript/collection.ts
    python/collection.py
    csharp/Collection.cs
    java/Collection.java (agents package)
    bash/collection.sh
    zsh/collection.zsh
    git/collection.sh
    github/collection.sh
    hpcc/collection.sh
  trigger_process_agent/
    swift/TriggerProcessAgent.swift
    objective-c/TriggerProcessAgent.h, TriggerProcessAgent.m
    ruby/agent.rb
    typescript/agent.ts
    python/agent.py
    csharp/TriggerProcessAgent.cs
    java/TriggerProcessAgent.java (agents package)
    bash/agent.sh
    zsh/agent.zsh
    git/agent.sh
    github/agent.sh
    hpcc/agent.sh
```

Each platform directory contains the collection (filter_agents) or the trigger process agent, with the same contract so they can be invoked from any language, project, repository, cluster, or model context.

## 4. Across languages, projects, repositories, clusters, and models

- **Languages**: Use the filter and trigger for the runtime you are in (Swift, Obj-C, Ruby, TypeScript, Python, C#, Java, Bash, Zsh).
- **Projects**: Each project under PROJECTS_DIR can load the agents from this directory (or from a copied path).
- **Repositories**: Each repo is a node in the blooming-directed-graph; filter by repo name, then trigger workflow_dispatch or git actions.
- **Clusters**: Use the **hpcc** filter and trigger for HPCC/Slurm (partition, job_submit); use **github** for GitHub Actions.
- **Models**: The 20 context keys (CONTEXT_KEYS.md) map to models (@granite, @deepseek, @qwen, @codellama); filter by action_where or action_client, then trigger the appropriate process (e.g. workflow for github, job for hpcc).
