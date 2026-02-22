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
  1. Generate/manage SSH keys
  2. Configure SSH config
  3. Handle known_hosts
  4. Test connectivity

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

## Fixed Ports (VPN Required)

| Port | Service | Model |
|------|---------|-------|
| 55077 | Ollama | granite4 |
| 55088 | Ollama | deepseek-r1 |
| 66044 | Ollama | qwen-coder |
| 66033 | Ollama | codellama |

## Rocky Linux 10 Best Practices

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

## Next Steps

1. Implement VPN detection
2. Build SSH key management
3. Create tunnel automation
4. Add comprehensive tests
