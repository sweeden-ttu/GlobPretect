# CI/CD setup across all projects

Use this to get the same CI/CD and commit-message standard in every project (GlobPretect, OllamaHpcc, brw-scan-print, etc.).

## 1. Commit message standard (all projects)

Every commit should trigger review and task routing via git message content:

- **Review:** @cursor @gemini @claude @actions-user  
  → CURSOR.md, GEMINI.md, CLAUDE.md, AGENTS.md
- **Tasks:** list with:
  - **Local:** @hpcc @macos @rockylinux
  - **Client:** @maclaptop @rockydesktop
  - **Server:** @actions-user @github-actions @hpcc-gpu @hpcc-cpu

Details: **docs/COMMIT_MESSAGE_STANDARD.md** (copy into each repo’s `docs/`).

## 2. GitHub Actions (each project)

Copy GlobPretect’s workflow into each repo so @actions-user / @github-actions run the same pattern:

```bash
# From repo root (e.g. GlobPretect, OllamaHpcc)
mkdir -p .github/workflows
cp /path/to/GlobPretect/.github/workflows/ci.yml .github/workflows/
git add .github/workflows/ci.yml docs/COMMIT_MESSAGE_STANDARD.md
git commit -m "Add CI and commit message standard"
```

Or create **.github/workflows/ci.yml** with:

- `on: push` / `pull_request` to main (and master if used).
- Job that checks for docs (AGENTS.md, CURSOR.md, GEMINI.md, CLAUDE.md) and runs lint/tests as appropriate.

## 3. Daily sync (commit message)

**daily-github-sync.sh** already builds commits with:

- Subject: e.g. `Daily sync YYYY-MM-DD`
- Body: Review (@cursor @gemini @claude @actions-user), Refs (CURSOR.md … AGENTS.md), Tasks (@macos @maclaptop, @rockylinux @rockydesktop, @hpcc @hpcc-gpu @hpcc-cpu, @actions-user @github-actions).

So running the sync script across all projects applies the standard commit format and triggers CI (and agent review) on push.

## 4. Per-project tweaks

- Add repo-specific steps in **.github/workflows/ci.yml** (e.g. run tests, build).
- In **COMMIT_MESSAGE_STANDARD.md** (or in-repo copy), adjust the example **Tasks:** lines to match that repo (e.g. “@hpcc-gpu: run Slurm job X”).
- Keep **Review:** and the list of docs (CURSOR.md, GEMINI.md, CLAUDE.md, AGENTS.md) the same so Cursor, Gemini, Claude, and GitHub Actions are triggered consistently.
