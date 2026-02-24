# Blooming-directed-graph – repos as nodes, GitHub Actions interaction

A **blooming-directed-graph** is a **directed graph** whose nodes are repositories and whose edges are directed (e.g. repo → github_actions). The term is specific and distinct from a generic "blooming graph".

Each repository under `~/projects` (except **data-structures**) is a **node**. Edges link each repo to **github_actions** (workflow runs). Ruby, Python, and TypeScript code in **src/** discover nodes and interact with the GitHub Actions API for each repo.

## Nodes

- **Projects dir:** `PROJECTS_DIR` (default `~/projects`).
- **Excluded:** `data-structures`.
- **Node:** name (dir name), path, owner/repo from `git remote get-url origin`.

## Edges

- Directed: each repo node → `github_actions` (when the repo has a GitHub remote).

## GitHub Actions API

All three implementations support:

- **List workflows** – `GET /repos/{owner}/{repo}/actions/workflows`
- **List workflow runs** – `GET /repos/{owner}/{repo}/actions/runs`
- **Trigger workflow_dispatch** – `POST /repos/{owner}/{repo}/actions/workflows/{id}/dispatches`

Set **GITHUB_TOKEN** (with `repo` and `actions` scope) for API calls.

## Running the code

### Ruby

```bash
cd /path/to/GlobPretect
export GITHUB_TOKEN=ghp_...
ruby src/ruby/blooming_directed_graph.rb
```

Requires: Ruby stdlib (json, net/http, uri, shellwords).

### Python

```bash
cd /path/to/GlobPretect
export GITHUB_TOKEN=ghp_...
python3 src/python/blooming_directed_graph.py
```

Requires: Python 3 (stdlib only: os, re, json, urllib.request, subprocess).

### TypeScript / Node

```bash
cd /path/to/GlobPretect
export GITHUB_TOKEN=ghp_...
npx ts-node src/typescript/blooming-directed-graph.ts
# or: node --loader ts-node/esm src/typescript/blooming-directed-graph.ts
```

Requires: Node 18+ (fetch), ts-node. Or compile and run:

```bash
npx tsc --outDir dist src/typescript/blooming-directed-graph.ts && node dist/blooming-directed-graph.js
```

## File layout

- **src/ruby/blooming_directed_graph.rb** – `BloomingDirectedGraph` class + CLI
- **src/python/blooming_directed_graph.py** – `BloomingDirectedGraph` class + `main()`
- **src/typescript/blooming-directed-graph.ts** – `BloomingDirectedGraph` class + `main()`

## Usage from code

- **Ruby:** `require_relative "blooming_directed_graph"`; `g = BloomingDirectedGraph.new`; `g.each_repo_workflows { |name, owner, repo, list| ... }`
- **Python:** `from blooming_directed_graph import BloomingDirectedGraph`; `g = BloomingDirectedGraph()`; `for name, owner, repo, list in g.each_repo_workflows(): ...`
- **TypeScript:** `import { BloomingDirectedGraph } from "./blooming-directed-graph"`; `const g = new BloomingDirectedGraph()`; `for await (const [name, owner, repo, list] of g.eachRepoWorkflows()) { ... }`

## Context keys

The blooming-directed-graph aligns with the 20 context keys (see **CONTEXT_KEYS.md**): keys with **github** imply action by the GitHub workflow agent; each repo's workflows are the Actions entry point for that node.

## Daily GitHub sync (test setup and action)

The blooming-directed-graph code is copied to the root of all 14 repositories under `~/projects`. To test the **daily GitHub sync** (from GlobPretect):

1. **Setup:** `cd GlobPretect && PROJECTS_DIR=~/projects ./scripts/daily-github-sync.sh setup` — then run `gh auth login` and `gh auth setup-git` if needed.
2. **Sync:** `PROJECTS_DIR=~/projects ./scripts/daily-github-sync.sh sync owner_github_granite` — requires the SSH key for that context key; commits and pushes all repos (including the copied `src/` and `docs/BLOOMING_DIRECTED_GRAPH.md`), triggering GitHub Actions where workflows exist.
