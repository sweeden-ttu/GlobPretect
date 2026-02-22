#!/bin/bash
# connect-hpcc.sh - Connect to HPCC RedRaider

SSH_KEY="$HOME/projects/GlobPretect/id_ed25519_sweeden"
HPCC_HOST="sweeden@login.hpcc.ttu.edu"

if [ ! -f "$SSH_KEY" ]; then
    echo "Error: SSH key not found at $SSH_KEY"
    exit 1
fi

echo "Connecting to HPCC RedRaider..."
ssh -i "$SSH_KEY" -o "AddKeysToAgent=yes" "$HPCC_HOST"
