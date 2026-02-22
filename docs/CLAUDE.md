# CLAUDE.md - GlobPretect VPN Development Guide

This document provides guidance for Claude AI when working on GlobPretect - a VPN connection manager and router for secure access to TTU HPCC (RedRaider) and local Ollama services.

## Project Overview

**GlobPretect** is a VPN connection manager that:
- Manages GlobalProtect VPN connections for TTU networks
- Routes traffic through specified interfaces for secure HPCC access
- Provides SSH tunnel management for Ollama GPU services on RedRaider
- Integrates with VS Code and Cursor for remote development

## Fixed Ollama Ports (VPN Required)

**IMPORTANT**: Always use fixed ports 55077 or 66044. Never use default port 11434.

| Variable | Port | Model | Purpose |
|----------|------|-------|---------|
| GRANITE_URL | 55077 | granite4 | Stable general model |
| THINK_URL | 55088 | deepseek-r1 | Dynamic thinking/reasoning |
| QWEN_URL | 66044 | qwen-coder | Code generation |
| CODE_URL | 66033 | codellama | Generic coding |

## Environments

### Environment 1: MacBook (owner@owner)
- **Host**: 192.168.0.14/24
- **Shell**: zsh
- **Projects**: ~/projects/
- **VPN**: GlobPretect active for Ollama ports

### Environment 2: Rocky Linux 10 (sdw3098@quay)
- **Host**: 192.168.0.15/24
- **Shell**: bash
- **Projects**: $HOME/projects/
- **VPN**: GlobPretect active for Ollama ports

### Environment 3: HPCC RedRaider (sweeden@login.hpcc.ttu.edu)
- **Login**: login.hpcc.ttu.edu → load balanced to login-20-25/26
- **Partitions**: nocona (CPU), matador (GPU V100), toreador (GPU A100)
- **Shell**: bash
- **VPN**: SSH tunnel required for local Ollama access
- **C Library**: glibc (can cross-compile for musl)

## musl vs glibc Builds

**IMPORTANT**: Different environments use different C libraries:

| Environment | C Library | Use For |
|------------|-----------|---------|
| HPCC RedRaider | glibc | musl cross-compilation, VPN builds |
| Rocky Linux 10 | glibc | Standard builds only |
| MacBook | libSystem | Native builds only |

**musl binary compilations ONLY work on HPCC cluster** because:
- HPCC runs Rocky Linux (glibc) which can cross-compile for musl targets
- musl is used by Alpine Linux containers
- MacBooks use BSD-based libSystem (incompatible)
- Rocky Linux 10 uses glibc (not musl-compatible)

## SSH Key Setup

### MacBook owner@owner
```bash
ssh-keygen -t ed25519 -C "sweeden@ttu.edu" -f ~/projects/GlobPretect/id_ed25519_sweeden
# Passphrase:  
```

### Rocky quay sdw3098
```bash
ssh-keygen -t ed25519 -C "sweeden@ttu.edu" -f $HOME/projects/GlobPretect/id_ed25519_sweeden
# Passphrase: 
```

### Copy to HPCC
```bash
ssh-copy-id -i ~/projects/GlobPretect/id_ed25519_sweeden.pub sweeden@login.hpcc.ttu.edu
# Password:  (one-time)
```

## API Keys File

**Location**: ~/ssapikeys.mine.donotlook

```bash
touch ~/ssapikeys.mine.donotlook && chmod 600 ~/ssapikeys.mine.donotlook
```

Contents:
```
LANGCHAIN_API_KEY=lsv2_your_langsmith_key_here
OPENAI_API_KEY=sk-proj-your_openai_key_here
GITHUB_TOKEN=ghp_your_github_token
```

Auto-load in shell:
```bash
# ~/.zshrc (Mac) or ~/.bashrc (Rocky)
if [ -f ~/ssapikeys.mine.donotlook ]; then
    export $(grep -v '^#' ~/ssapikeys.mine.donotlook | xargs)
fi
```

## VPN Connection Manager

### GlobPretect CLI

```python
# src/python/globpretect/__init__.py
import subprocess
import socket
import os

class VPNManager:
    """Manages VPN connections and routing."""
    
    def __init__(self):
        self.ssh_key = os.path.expanduser("~/projects/GlobPretect/id_ed25519_sweeden")
        self.hpcc_host = "sweeden@login.hpcc.ttu.edu"
        
    def check_vpn_active(self):
        """Check if VPN is active for Ollama ports."""
        ports = [55077, 55088, 66044, 66033]
        active = []
        for port in ports:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1)
            result = sock.connect_ex(('127.0.0.1', port))
            if result == 0:
                active.append(port)
            sock.close()
        return active
    
    def establish_tunnel(self, local_port, remote_port, remote_host="localhost"):
        """Establish SSH tunnel for port forwarding."""
        cmd = [
            "ssh", "-i", self.ssh_key,
            "-L", f"{local_port}:{remote_host}:{remote_port}",
            "-N", "-f", self.hpcc_host
        ]
        subprocess.run(cmd)
        
    def start_ollama_tunnels(self):
        """Start all Ollama port tunnels."""
        tunnels = [
            (55077, 55077),  # granite4
            (55088, 55088),  # deepseek-r1
            (66044, 66044),  # qwen-coder
            (66033, 66033),  # codellama
        ]
        for local, remote in tunnels:
            self.establish_tunnel(local, remote)
```

## HPCC Connection

### Interactive GPU Session
```bash
# Request GPU node on matador (V100) or toreador (A100)
srun -p matador --gpus-per-node=1 -t 02:00:00 --pty bash
# Or
srun -p toreador --gpus-per-node=2 -t 04:00:00 --pty bash
```

### Slurm Job Script
```bash
#!/bin/bash
#SBATCH -J ollama_job
#SBATCH -o %x.o%j
#SBATCH -e %x.e%j
#SBATCH -p matador
#SBATCH --gpus-per-node=1
#SBATCH -t 02:00:00

module load gcc cuda podman
podman run -d -p 55077:55077 --name ollama-granite4 \
  -v ollama:/root/.ollama \
  -e OLLAMA_HOST=0.0.0.0:55077 \
  quay.io/ollama/ollama serve
podman exec ollama-granite4 ollama pull granite4
```

## LangChain Integration

```python
import os
from dotenv import load_dotenv
from langchain_community.llms import Ollama

load_dotenv(dotenv_path=os.path.expanduser("~/ssapikeys.mine.donotlook"))

PORTS = {
    "granite": "http://localhost:55077",
    "think": "http://localhost:55088", 
    "qwen": "http://localhost:66044",
    "code": "http://localhost:66033"
}

def get_llm(model_type):
    return Ollama(model=model_type, base_url=PORTS[model_type])

# Usage
llm = get_llm("granite")
response = llm.invoke("Explain quantum computing")
```

## VS Code / Cursor Integration

### Remote Development to HPCC
1. Install "Remote - SSH" extension
2. Connect to: `sweeden@login.hpcc.ttu.edu`
3. Use SSH key: `~/projects/GlobPretect/id_ed25519_sweeden`

### Ollama in VS Code
1. Install "Ollama" extension
2. Configure endpoint in settings:
   - granite4: http://localhost:55077
   - deepseek-r1: http://localhost:55088

### Cursor IDE
1. Settings → Models → Ollama
2. Add endpoints for each port
3. Set default model per task

## Development Philosophy

### Incremental Development
1. **Local first**: Test with local Ollama containers
2. **HPCC second**: Validate on GPU nodes
3. **Production**: Deploy with monitoring

### Testing Strategy
```python
# test/test_vpn.py
import unittest
from globpretect import VPNManager

class TestVPNManager(unittest.TestCase):
    def test_check_vpn_active(self):
        vm = VPNManager()
        active = vm.check_vpn_active()
        self.assertIsInstance(active, list)
        
    def test_ollama_ports(self):
        vm = VPNManager()
        active = vm.check_vpn_active()
        expected = [55077, 55088, 66044, 66033]
        for port in expected:
            self.assertIn(port, active, f"Port {port} should be active")
```

## File Structure

```
GlobPretect/
├── docs/
│   ├── CLAUDE.md          # This file
│   ├── AGENTS.md          # Multi-agent guide
│   ├── README.md          # Project overview
│   └── SETUP/
│       └── INSTALL.md     # Installation guide
├── scripts/
│   ├── connect-hpcc.sh    # SSH to HPCC
│   ├── start-tunnels.sh   # Start Ollama tunnels
│   └── test-ports.sh      # Test VPN ports
├── src/python/
│   └── globpretect/
│       ├── __init__.py    # Main module
│       ├── vpn.py         # VPN manager
│       └── tunnel.py      # SSH tunnel manager
└── test/python/
    └── test_vpn.py        # Unit tests
```

## Common Issues

### Issue: SSH key not working
**Solution**: Add to ssh-agent
```bash
ssh-add ~/projects/GlobPretect/id_ed25519_sweeden
```

### Issue: VPN ports not accessible
**Solution**: Ensure GlobPretect VPN is active
```bash
ping 192.168.0.14  # MacBook
ping 192.168.0.15  # Rocky quay
```

### Issue: HPCC connection refused
**Solution**: Check known_hosts
```bash
ssh-keygen -R login.hpcc.ttu.edu
ssh -i ~/projects/GlobPretect/id_ed25519_sweeden sweeden@login.hpcc.ttu.edu
```

## Next Steps

1. Set up SSH keys on both machines
2. Configure ~/ssapikeys.mine.donotlook
3. Test local Ollama containers
4. Establish SSH tunnel to HPCC
5. Deploy Ollama on matador GPU node
6. Integrate with VS Code / Cursor
