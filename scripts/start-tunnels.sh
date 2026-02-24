#!/bin/bash
# start-tunnels.sh - Start Ollama SSH tunnels to HPCC
#
# SSH key: four factors (see ssh-key-standard.sh) - USER, HOSTNAME, hpcc, sweeden.
# Ports: production 55077,55088,66044,66033; testing 55177,55188,66144,66133 (set USE_TEST_PORTS=1).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./ssh-key-standard.sh
source "$SCRIPT_DIR/ssh-key-standard.sh"

HPCC_HOST="login.hpcc.ttu.edu"
ssh_std_set_key "hpcc" || exit 1
HPCC_FULL="${REMOTE_USER}@${HPCC_HOST}"

# Port-to-model: production (AGENTS.md); testing = middle digit +1
if [[ "${USE_TEST_PORTS:-0}" == "1" ]]; then
    PORTS=(55177 55188 66144 66133)
else
    PORTS=(55077 55088 66044 66033)
fi

echo "Starting Ollama SSH tunnels (ports: ${PORTS[*]})..."

for PORT in "${PORTS[@]}"; do
    echo "Tunnel: localhost:$PORT -> $HPCC_FULL:$PORT"
    ssh -i "$SSH_KEY" -L "$PORT:localhost:$PORT" -N -f "$HPCC_FULL" &
done

echo "All tunnels started."
echo "Verify with: lsof -i :${PORTS[0]} -i :${PORTS[1]} -i :${PORTS[2]} -i :${PORTS[3]}"
