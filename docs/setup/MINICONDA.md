# SETUP.md - GlobPretect Miniconda Environment

## Quick Start

```bash
# Install Miniconda (if not already)
curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda3
source $HOME/miniconda3/etc/profile.d/conda.sh

# Create environment
conda create -n globpretect python=3.12 pip paramiko requests python-dotenv -y

# Activate
conda activate globpretect

# Install globpretect
cd ~/projects/GlobPretect
pip install -e .
```

## HPCC Setup

```bash
#!/bin/bash
#SBATCH -J vpn-job
#SBATCH -p nocona
#SBATCH -t 01:00:00

# Load modules
module load gcc

# Initialize conda
source $HOME/miniconda3/etc/profile.d/conda.sh
conda activate globpretect

# Run VPN operations
python -c "from globpretect import VPNManager; vm = VPNManager(); print(vm.get_status())"
```

## Environment Dependencies

| Package | Purpose |
|---------|---------|
| paramiko | SSH connections |
| requests | HTTP/API calls |
| python-dotenv | Environment variables |
| pyyaml | Config files |

## Verify Installation

```bash
python -c "from globpretect import VPNManager; print('OK')"
```
