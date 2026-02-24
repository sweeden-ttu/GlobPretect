# AGENTS.md - GlobPretect Multi-Agent Development Guide

This document provides guidance for autonomous agent systems working on GlobPretect - VPN connection manager and router.

## Project Overview

**GlobPretect** manages VPN connections for secure access to:
- TTU HPCC (RedRaider) cluster
- Ollama GPU services
- Local network resources

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Agent Coordinator                            │
└─────────────────────────────────────────────────────────────────┘
          │              │              │              │
    ┌─────▼─────┐  ┌─────▼─────┐  ┌─────▼─────┐  ┌─────▼─────┐
    │   VPN     │  │   SSH    │  │  Tunnel  │  │  Testing  │
    │  Agent    │  │  Agent   │  │  Agent   │  │  Agent    │
    └───────────┘  └───────────┘  └───────────┘  └───────────┘
```

## Agent Responsibilities

### Agent 1: VPN Management
- **Goal**: Manage GlobalProtect VPN connections
- **Tasks**:
  1. Detect VPN status
  2. Connect/disconnect VPN
  3. Verify port accessibility
  4. Handle reconnection

### Agent 2: SSH Integration
- **Goal**: SSH key and connection management
- **Tasks**:
  1. Generate/manage SSH keys (four-factor naming, see below)
  2. Configure SSH config
  3. Handle known_hosts
  4. Test connectivity

## SSH Key Standard (All Scripts)

SSH keys use **four factors** (hostname, user, remote_user, remote_cluster) and are stored in `~/.ssh` (never in the project).

**Key path:** `~/.ssh/id_ed25519_${HOSTNAME}_${USER}_${REMOTE_USER}_${REMOTE_CLUSTER}`  
**SSH_KEY_IDENTIFIER:** `${HOSTNAME}_${USER}_${REMOTE_USER}_${REMOTE_CLUSTER}`

### Five valid SSH_KEY_IDENTIFIERs

| # | Identifier | Use | Status |
|---|------------|-----|--------|
| 1 | `owner_owner_sweeden_hpcc` | macOS → HPCC | Implemented |
| 2 | `owner_owner_sweeden-ttu_github` | macOS → GitHub | Not yet implemented |
| 3 | `sweeden_hpcc_sweeden-ttu_github` | HPCC → GitHub | Not yet implemented |
| 4 | `quay_sdw3098_sweeden_hpcc` | Rocky Linux → HPCC | Not yet implemented |
| 5 | `quay_sdw3098_sweeden-ttu_github` | Rocky Linux → GitHub | Implemented (not current machine) |

Scripts source `scripts/ssh-key-standard.sh` for consistent key paths and HPCC context.

### Four valid OLLAMA_MODEL_IDENTIFIERs

| # | Model identifier | Port (production) | Port (testing) | Git handle |
|---|------------------|-------------------|-----------------|------------|
| 1 | granite4 | 55077 | 55177 | @granite |
| 2 | deepseek-r1 | 55088 | 55188 | @deepseek |
| 3 | qwen-coder | 66044 | 66144 | @qwen |
| 4 | codellama | 66033 | 66133 | @codellama |

- **@ollama-instruct** = instructions for Ollama to run (in git messages/notifications). See **docs/COMMIT_MESSAGE_STANDARD.md** for all handles.

There are 5 SSH_KEY_IDENTIFIERs × 4 OLLAMA_MODEL_IDENTIFIERs = **20 unique context keys** that always identify context, sender, and receiver. See **docs/CONTEXT_KEYS.md** for the full list and naming scheme (e.g. `owner_hpcc_granite`, `quay_github_qwen`). End-to-end flow (origin → github-actions → HPCC → Ollama → @actions-user → comments with @macbook/@rockydesktop) and git hooks for fetch_and_merge: **docs/LANGFLOW_STATE_DIAGRAM.md**, **docs/GIT_HOOKS.md**.

### Where the action runs (from the key)

- **github** in the key → action is taken by the **GitHub workflow action agent** (this CI, @actions-user, comments, releases).
- **hpcc** in the key → action is taken **at the HPCC cluster** (jobs, Ollama, compute).
- **owner** (origin) → action can be taken **locally on macbook** (@macos @maclaptop).
- **quay** (origin) → action can be taken **locally on rockydesktop** (@rockylinux @rockydesktop).

Scripts use `CONTEXT_ACTION_WHERE` (github | hpcc) and `CONTEXT_ACTION_CLIENT` (macbook | rockydesktop) from **scripts/context-key.sh**; see **docs/CONTEXT_KEYS.md**.

## HPCC: When Already on Cluster (login*, gpu*-*, cpu*-*)

When hostname matches `login*`, `gpu*-*`, or `cpu*-*` (e.g. login20-2, gpu2-12, cpu8-1), the machine is already on the HPCC cluster. When hostname **begins with "login"**, one more step is required to reserve compute resources:

- **HPCC Interactive:** Run `/etc/slurm/scripts/interactive`, wait one minute, then verify hostname has changed to `gpu*-*` or `cpu*-*`.
- **HPCC Non-interactive:** Use `squeue -u sweeden`; `scancel <jobID>` to cancel; `sinfo` to verify partition (matador) and GPU modules; set `OLLAMA_MODEL_$JOBID="$PORT":"$MODEL"` for the job.

### Agent 3: Tunnel Management
- **Goal**: SSH tunnel for Ollama ports
- **Tasks**:
  1. Establish port forwards
  2. Monitor tunnel health
  3. Auto-reconnect tunnels
  4. Clean up stale tunnels

### Agent 4: Testing & QA
- **Goal**: Comprehensive testing
- **Tasks**:
  1. Unit tests for each module
  2. Integration tests
  3. VPN connectivity tests
  4. HPCC access tests

## Fixed Ports (Debug – VPN Required)

| Port | Service | Model |
|------|---------|-------|
| 55077 | Ollama | granite |
| 55088 | Ollama | deepseek |
| 66044 | Ollama | qwen-coder |
| 66033 | Ollama | codellama |

## Fixed Ports (Testing – Middle Digit +1 runs on macOS)

| Port | Service | Model |
|------|---------|-------|
| 55177 | Ollama | granite |
| 55188 | Ollama | deepseek |
| 66144 | Ollama | qwen-coder |
| 66133 | Ollama | codellama |

## Fixed Ports (Testing – Middle Digit +2 runs on RockyLinux)

## Fixed Ports (Ready for Release)
| Port | Service | Model |
|------|---------|-------|
| 55277 | Ollama | granite |
| 55288 | Ollama | deepseek |
| 66244 | Ollama | qwen-coder |
| 66233 | Ollama | codellama |

## Fixed Ports (Release – Middle Digit +3 runs on RockyLinux/MacOS)

## Fixed Ports (Ready for Release)
| Port | Service | Model |
|------|---------|-------|
| 55377 | Ollama | granite |
| 55388 | Ollama | deepseek |
| 66344 | Ollama | qwen-coder |
| 66333 | Ollama | codellama |

## Rocky Linux 10 Best Practices
Until the release number of GlobPretect reaches "2.0" use the release number of this repository to set the middle number of the port ranges.

### Python Environment
```bash
module install python 3.12.0
pip install paramiko requests python-dotenv
```

### SSH Libraries
```python
import paramiko  # SSH connections
import subprocess  # System commands
```

## File Structure

```
GlobPretect/
├── docs/
│   ├── CLAUDE.md
│   ├── AGENTS.md          # This file
│   └── SETUP/INSTALL.md
├── scripts/
│   ├── ssh-key-standard.sh   # Four-factor key naming, HPCC context (source in other scripts)
│   ├── connect-hpcc.sh
│   ├── start-tunnels.sh
│   └── test-ports.sh
├── src/python/globpretect/
│   ├── __init__.py
│   ├── vpn.py
│   ├── ssh.py
│   └── tunnel.py
└── test/python/
    └── test_vpn.py
```

## Communication Protocol

Agents communicate via:
1. **Shared state files**: JSON in `state/` directory
2. **Lock files**: Prevent race conditions
3. **Log files**: Track all operations

## CI/CD and commit messages (@actions-user)

- **GitHub Actions** run on push/PR (`.github/workflows/ci.yml`). They reference this file and CURSOR.md, GEMINI.md, CLAUDE.md for @actions-user behavior.
- **Commit messages** must include **Review:** @cursor @gemini @claude @actions-user and a **Tasks:** list for @macos @maclaptop @rockylinux @rockydesktop @hpcc @hpcc-gpu @hpcc-cpu @actions-user @github-actions so local and server-side follow-up is clear. See **docs/COMMIT_MESSAGE_STANDARD.md**.

## Next Steps

1. Implement VPN detection
2. Build SSH key management
3. Create tunnel automation
4. Add comprehensive tests
