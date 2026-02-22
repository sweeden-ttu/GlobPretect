#!/bin/bash
# start-tunnels.sh - Start Ollama SSH tunnels

SSH_KEY="$HOME/projects/GlobPretect/id_ed25519_sweeden"
HPCC_HOST="sweeden@login.hpcc.ttu.edu"

PORTS=(55077 55088 66044 66033)

echo "Starting Ollama SSH tunnels..."

for PORT in "${PORTS[@]}"; do
    echo "Tunnel: localhost:$PORT -> $HPCC_HOST:$PORT"
    ssh -i "$SSH_KEY" -L "$PORT:localhost:$PORT" -N -f "$HPCC_HOST" &
done

echo "All tunnels started."
echo "Verify with: lsof -i :55077 -i :55088 -i :66044 -i :66033"
