#!/bin/bash
# start-tunnels.sh - Start Ollama SSH tunnels to HPCC
#
# Accepts one of the 20 context keys (CONTEXT_KEY or first arg). Decision: only run when key receiver is HPCC (*_hpcc_*).
# SSH key from key; tunnel the port for the key's model (or all four production ports if TUNNEL_ALL=1).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTEXT_KEY="${1:-$CONTEXT_KEY}"
# shellcheck source=./context-key.sh
source "$SCRIPT_DIR/context-key.sh"
context_key_require
# Decision: only tunnel to HPCC when key receiver is HPCC
if [[ "$CONTEXT_RECEIVER" != "hpcc" ]]; then
    echo "Key $CONTEXT_KEY has receiver $CONTEXT_RECEIVER; start-tunnels is for HPCC only. Use a *_hpcc_* key." >&2
    exit 1
fi
# shellcheck source=./ssh-key-standard.sh
source "$SCRIPT_DIR/ssh-key-standard.sh"
ssh_std_set_key_from_context || ssh_std_set_key "hpcc" || exit 1
HPCC_HOST="login.hpcc.ttu.edu"
HPCC_FULL="${REMOTE_USER}@${HPCC_HOST}"

# Port(s): from key (single model port) or all four if TUNNEL_ALL=1
if [[ "${TUNNEL_ALL:-0}" == "1" ]]; then
    if [[ "${USE_TEST_PORTS:-0}" == "1" ]]; then
        PORTS=(55177 55188 66144 66133)
    else
        PORTS=(55077 55088 66044 66033)
    fi
else
    PORTS=("${OLLAMA_PORT:-55077}")
fi

echo "Starting Ollama SSH tunnel(s) for key $CONTEXT_KEY (ports: ${PORTS[*]})..."

for PORT in "${PORTS[@]}"; do
    echo "Tunnel: localhost:$PORT -> $HPCC_FULL:$PORT"
    ssh -i "$SSH_KEY" -L "$PORT:localhost:$PORT" -N -f "$HPCC_FULL" &
done

echo "Tunnel(s) started. Verify with: lsof -i :${PORTS[0]}"
