# Commit Message Standard – CI/CD and Agent Triggers

All git commit messages should follow this format so that **@cursor** (CURSOR.md), **@gemini** (GEMINI.md), **@claude** (CLAUDE.md), and **@actions-user** (AGENTS.md + GitHub Actions) can trigger review and CI/CD as appropriate. The message must include a **task list** indicating where follow-up is needed: local machines, client side, or server side.

## Format

```
<subject line (e.g. Daily sync YYYY-MM-DD)>

Review: @cursor @gemini @claude @actions-user
Refs: CURSOR.md GEMINI.md CLAUDE.md AGENTS.md

Tasks:
- @<target>: <action or "no action">
...
```

## Agent / review handles (for CI/CD and docs)

| Handle        | Doc         | Role |
|---------------|-------------|------|
| **@cursor**   | CURSOR.md   | Cursor IDE rules, Ollama endpoints, project rules |
| **@gemini**   | GEMINI.md   | Gemini Code Assist, VPN/Ollama ports, MCP |
| **@claude**   | CLAUDE.md   | Claude guidance, envs (MacBook, Rocky, HPCC), SSH keys |
| **@actions-user** | AGENTS.md + .github/workflows | GitHub Actions, agent responsibilities, automation |

## Ollama / model handles (git messages and notifications)

Use these in commit messages or notifications when referring to Ollama models or instructing Ollama to run something.

| Handle | Model / meaning |
|--------|------------------|
| **@granite** | Ollama **granite4** model (port 55077 prod, 55177 test) |
| **@codellama** | Ollama **codellama** model (port 66033 prod, 66133 test) |
| **@qwen** | Ollama **qwen-coder** model (port 66044 prod, 66144 test) |
| **@deepseek** | Ollama **deepseek-r1** model (port 55088 prod, 55188 test) |
| **@ollama-instruct** | Instructions for **Ollama to run** (prompts, commands, or job steps that Ollama should execute) |

Example: *“Use @granite for summaries; @ollama-instruct: run the pipeline on HPCC.”*

For a unique context (sender + receiver + model), use one of the **20 context keys** (e.g. `owner_hpcc_granite`, `quay_github_codellama`). See **docs/CONTEXT_KEYS.md**.

## Task list targets (where work runs)

Use these in the **Tasks:** section to say who should act or that no action is needed.

### Local / environment

| Handle          | Meaning |
|-----------------|---------|
| **@hpcc**       | HPCC cluster (login/gpu/cpu nodes) – run jobs, tunnels, or no action |
| **@macos**      | macOS (e.g. owner@owner) – run scripts, VPN, sync |
| **@rockylinux** | Rocky Linux (e.g. sdw3098@quay) – run scripts, build |

### Client side

| Handle           | Meaning |
|------------------|---------|
| **@maclaptop**   | Mac laptop – client-side changes (VPN, SSH, sync) |
| **@rockydesktop**| Rocky desktop – client-side changes |

### Server side

| Handle            | Meaning |
|-------------------|---------|
| **@actions-user** | GitHub Actions / automation user |
| **@github-actions**| GitHub Actions workflows (e.g. .github/workflows) |
| **@hpcc-gpu**     | HPCC GPU partition (matador) – Ollama/GPU jobs |
| **@hpcc-cpu**     | HPCC CPU partition (nocona) – CPU jobs |

## Example (daily sync)

```
Daily sync 2025-02-23

Review: @cursor @gemini @claude @actions-user
Refs: CURSOR.md GEMINI.md CLAUDE.md AGENTS.md

Tasks:
- @macos @maclaptop: run daily-github-sync; verify VPN/GlobPretect if needed
- @rockylinux @rockydesktop: run daily-github-sync if applicable
- @hpcc @hpcc-gpu @hpcc-cpu: no action unless HPCC jobs or tunnels changed
- @actions-user @github-actions: CI runs on push (see .github/workflows)
```

## Example (HPCC / code change)

```
Add Ollama tunnel script for matador

Review: @cursor @gemini @claude @actions-user
Refs: CURSOR.md GEMINI.md CLAUDE.md AGENTS.md

Tasks:
- @macos @maclaptop: pull and run start-tunnels.sh
- @hpcc @hpcc-gpu: deploy/run Slurm job; set OLLAMA_MODEL_$JOBID
- @actions-user @github-actions: CI runs on push
```

## Reuse across projects

- Copy this standard (or link to it) into each project under `docs/`.
- Use the same **Review:** and **Tasks:** format so Cursor, Gemini, Claude, and GitHub Actions can parse it consistently.
- Ensure each repo has `.github/workflows/` that reference AGENTS.md (or equivalent) for @actions-user behavior.
