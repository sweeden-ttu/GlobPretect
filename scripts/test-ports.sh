#!/bin/bash
# test-ports.sh - Test Ollama ports for a context key (or all four if TEST_ALL_PORTS=1)
#
# Accepts one of the 20 context keys (CONTEXT_KEY or first arg). Decision: test the port for the key's model, or all four if TEST_ALL_PORTS=1.
# Production: 55077,55088,66044,66033. Testing: 55177,55188,66144,66133 (USE_TEST_PORTS=1).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTEXT_KEY="${1:-$CONTEXT_KEY}"
# shellcheck source=./context-key.sh
source "$SCRIPT_DIR/context-key.sh"
context_key_require

if [[ "${TEST_ALL_PORTS:-0}" == "1" ]]; then
    if [[ "${USE_MACOS_PORTS:-0}" == "1" ]]; then
        PORTS=(55177 55188 66144 66133)
    else if [[ "${USE_ROCKYLINUX_PORTS:-0}" == "2" ]]; then
        PORTS=(55277 55288 66244 66233)
    else  
        PORTS=(55077 55088 66044 66033)
    fi
    NAMES=("granite4" "deepseek-r1" "qwen-coder" "codellama")
else
    PORTS=("${OLLAMA_PORT:-55077}")
    NAMES=("${CONTEXT_MODEL:-granite}")
fi

echo "Testing Ollama port(s) for key $CONTEXT_KEY (${PORTS[*]})..."
echo ""

for i in "${!PORTS[@]}"; do
    PORT="${PORTS[$i]}"
    NAME="${NAMES[$i]:-port}"
    if nc -z localhost "$PORT" 2>/dev/null; then
        echo "✓ $PORT ($NAME) - OPEN"
    else
        echo "✗ $PORT ($NAME) - CLOSED"
    fi
done

echo ""
echo "Testing API endpoints..."
for PORT in "${PORTS[@]}"; do
    if curl -s "http://localhost:$PORT/api/tags" >/dev/null 2>&1; then
        echo "✓ API on $PORT - OK"
    else
        echo "✗ API on $PORT - FAILED"
    fi
done
