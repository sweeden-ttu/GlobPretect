# Git hooks – @macbook / @rockydesktop on fetch_and_merge

Hooks in **.githooks/** run when certain events occur. The **post-merge** hook fires when **@macbook** or **@rockydesktop** appears in any commit message that was just merged (e.g. during `fetch_and_merge` in daily-github-sync).

## Hook: post-merge

- **When:** After `git merge` (e.g. when daily-github-sync runs fetch_and_merge and merges `origin/main`).
- **What:** Scans merged commits (`ORIG_HEAD..HEAD`) for `@macbook` or `@rockydesktop` in the commit body.
- **Then:** If found, runs **.githooks/on-macbook-comment** if it exists and is executable (with repo root and merged messages).

## Hook: on-macbook-comment

- **When:** Invoked by post-merge when a merged commit mentions @macbook or @rockydesktop.
- **Purpose:** Customize per repo (e.g. notify, run a local sync, update a dashboard).
- **Args:** `$1` = repo root, merged commit messages are passed for inspection.

## Install hooks in this repo (and others)

Use the shared hooks directory so merges in this repo run the hook:

```bash
cd /path/to/GlobPretect
git config core.hooksPath .githooks
chmod +x .githooks/post-merge
chmod +x .githooks/on-macbook-comment
```

To use the same behavior in another project (e.g. OllamaHpcc, brw-scan-print):

```bash
cd /path/to/other-repo
git config core.hooksPath /path/to/GlobPretect/.githooks
# or copy: cp -r /path/to/GlobPretect/.githooks . && git config core.hooksPath .githooks
chmod +x .githooks/post-merge .githooks/on-macbook-comment
```

## Install hooks for all projects in the workspace (fetch_and_merge)

To set up post-merge and on-macbook-comment for **every git repo** under your projects directory (same set of repos used by `daily-github-sync.sh`), run:

```bash
# From GlobPretect repo (PROJECTS_DIR defaults to $HOME/projects)
./scripts/install-git-hooks-all-repos.sh

# Or via daily-github-sync (same PROJECTS_DIR as sync)
./scripts/daily-github-sync.sh install-hooks

# Custom workspace directory
PROJECTS_DIR=/path/to/workspace ./scripts/install-git-hooks-all-repos.sh
```

This script:

- Finds every directory under `PROJECTS_DIR` that has a `.git` (same logic as daily-github-sync).
- For the repo that contains `.githooks` (GlobPretect): sets `core.hooksPath` to `.githooks` (relative).
- For all other repos: sets `core.hooksPath` to the **absolute path** of `GlobPretect/.githooks` so they all share the same hooks.
- Ensures `post-merge` and `on-macbook-comment` are executable.

After this, whenever `fetch_and_merge` runs (e.g. during `daily-github-sync.sh sync`), `git merge` will trigger the post-merge hook in each repo that had a merge, and the hook will run `on-macbook-comment` when merged commits mention @macbook or @rockydesktop.

## Flow (daily-github-sync)

1. **fetch_and_merge** runs `git fetch origin` then `git merge origin/$branch`.
2. After a successful merge, Git runs **.githooks/post-merge** (if `core.hooksPath` is set).
3. **post-merge** checks merged commit messages for @macbook / @rockydesktop.
4. If found, it runs **on-macbook-comment** so you can react locally (e.g. on @macbook or @rockydesktop).

This ties into the LangFlow state diagram: comments and release versions created by @actions-user with @macbook or @rockydesktop in the message are picked up on the next fetch_and_merge on that client.
