#!/bin/bash
# test-ports.sh - Test Ollama ports (production or testing set)
#
# Production: 55077,55088,66044,66033. Testing: 55177,55188,66144,66133 (USE_TEST_PORTS=1).

if [[ "${USE_TEST_PORTS:-0}" == "1" ]]; then
    PORTS=(55177 55188 66144 66133)
else
    PORTS=(55077 55088 66044 66033)
fi
NAMES=("granite4" "deepseek-r1" "qwen-coder" "codellama")

echo "Testing Ollama ports (${PORTS[*]})..."
echo ""

for i in "${!PORTS[@]}"; do
    PORT="${PORTS[$i]}"
    NAME="${NAMES[$i]}"
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
