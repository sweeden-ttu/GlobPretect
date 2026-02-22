# GEMINI.md - Gemini AI Development Guide

This document provides guidance for Gemini AI when working on GlobPretect.

## Project Context

**GlobPretect** - VPN connection manager for TTU HPCC access
- Manages GlobalProtect VPN connections
- Routes traffic for secure HPCC access
- Provides SSH tunnel management for Ollama GPU services

## Gemini Code Assist - Agent Mode (2025-2026)

### Overview

Gemini Code Assist now supports **Agent Mode** for enhanced pair programming in VS Code and IntelliJ IDEs. Agent Mode allows Gemini to:
- Analyze entire codebases and implement multi-file features
- Propose plans and await approval before changes
- Use MCP servers for extended capabilities
- Handle complex, multi-step tasks autonomously

### Key Features (October 2025 Update)

| Feature | Description |
|---------|-------------|
| **Agent Mode** | Multi-step autonomous coding with Gemini 2.5 Pro |
| **MCP Support** | Model Context Protocol integration (1800+ servers) |
| **1M Context** | Understand entire codebases with Gemini 2.5 Flash/Pro |
| **Free Tier** | 180K free completions/month (90x GitHub Copilot) |

### Agent Mode Workflow

```
User Prompt → Gemini API + Available Tools → Plan Generation → User Approval → Execution
```

### Model Selection

| Model | Context | Max Context | Best For |
|-------|---------|-------------|----------|
| Gemini 2.5 Pro | 200K | 1M | Complex reasoning, full codebase |
| Gemini 2.5 Flash | 200K | 1M | Speed-optimized tasks |

### MCP Integration (October 2025)

Gemini now supports Model Context Protocol for connecting to external tools:

```json
// .gemini/config.json
{
  "workspaces": ["packages/web", "packages/mobile"],
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"]
    }
  }
}
```

**Migration Deadline**: March 2026 - Legacy Tool Calling API deprecated

## Fixed Ollama Ports (VPN Required)

**IMPORTANT**: Always use fixed ports 55077 or 66044. Never use default port 11434.

| Port | Model | Agent Role |
|------|-------|------------|
| 55077 | granite4 | Agentic - high-level decision making, tool selection |
| 66044 | qwen2.5-coder | Coding - code generation, debugging |

## Gemini-Specific Guidelines

### VPN Management Tasks

Use Gemini for:
1. **Network Analysis** - Analyze VPN connectivity issues (port 55088)
2. **Security Audits** - Review security configurations
3. **Troubleshooting** - Debug connection problems
4. **Code Generation** - Generate tunnel management code (port 66044)

### Model Selection by Task

```python
# Complex reasoning about VPN routing
port = 55088  # deepseek-r1

# Code for tunnel management
port = 66044  # qwen-coder

# Documentation updates
port = 66033  # codellama

# General VPN operations
port = 55077  # granite4
```

### API Integration

```python
import requests

def query_vpn_llm(prompt, task_type="coding"):
    ports = {
        "agentic": 55077,
        "large": 55088,
        "coding": 66044,
        "plain": 66033
    }
    port = ports[task_type]
    response = requests.post(
        f"http://localhost:{port}/api/generate",
        json={"model": "qwen2.5-coder", "prompt": prompt}
    )
    return response.json()
```

## GitHub Integration

**Repository**: github.com/sweeden-ttu/GlobPretect

```bash
git clone git@github.com:sweeden-ttu/GlobPretect.git
cd GlobPretect
git config user.email "sweeden@ttu.edu"
git config user.name "sweeden-ttu"
```

## Development Workflow

1. **Analyze VPN issues** - Use port 55088 (deep reasoning)
2. **Implement fixes** - Use port 66044 (code generation)
3. **Document changes** - Use port 66033 (plain English)
4. **Test solutions** - Use port 55077 (agentic)

## Important Notes

- All Ollama operations require VPN active
- Fixed ports: 55077 (granite4), 66044 (qwen-coder)
- Never use default port 11434
- SSH key: ~/projects/GlobPretect/id_ed25519_sweeden
- MCP migration required by March 2026
