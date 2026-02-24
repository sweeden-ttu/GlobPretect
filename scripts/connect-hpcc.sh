#!/bin/bash
# connect-hpcc.sh - Connect to HPCC RedRaider
#
# Accepts one of the 20 context keys (CONTEXT_KEY or first arg). Decision: only run if key receiver is HPCC (*_hpcc_*).
# SSH key is chosen from the key (owner_hpcc or quay_hpcc). When on HPCC (login*|gpu*-*|cpu*-*), reserve resources if login.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTEXT_KEY="${1:-$CONTEXT_KEY}"
# shellcheck source=./context-key.sh
source "$SCRIPT_DIR/context-key.sh"
context_key_require
# Decision: only connect to HPCC when key receiver is HPCC
if [[ "$CONTEXT_RECEIVER" != "hpcc" ]]; then
    echo "Key $CONTEXT_KEY has receiver $CONTEXT_RECEIVER; connect-hpcc is for HPCC only. Use a *_hpcc_* key." >&2
    exit 1
fi
# shellcheck source=./ssh-key-standard.sh
source "$SCRIPT_DIR/ssh-key-standard.sh"
ssh_std_set_key_from_context || ssh_std_set_key "hpcc" || exit 1
HPCC_HOST="login.hpcc.ttu.edu"
HPCC_FULL="${REMOTE_USER}@${HPCC_HOST}"

# If we're already on the HPCC cluster (login*, gpu*-*, cpu*-*), handle login-node reservation
if ssh_std_on_hpcc; then
    if ssh_std_on_hpcc_login; then
        echo "Already on HPCC login node ($_ssh_std_hostname). Reserve resources (interactive or non-interactive)."
        if [[ "${HPCC_NONINTERACTIVE:-0}" == "1" ]]; then
            ssh_std_hpcc_reserve_noninteractive_help
        else
            ssh_std_hpcc_reserve_interactive
        fi
    else
        echo "Already on HPCC compute node ($_ssh_std_hostname). No further step."
    fi
    exit 0
fi

# Apple Terminal: enable Palo Alto VPN background before connecting (only for owner_* key)
if [ -n "${TERM_PROGRAM:-}" ] && [ "$TERM_PROGRAM" = "Apple_Terminal" ] && [ "$CONTEXT_ORIGIN" = "owner" ]; then
    echo "Apple Terminal detected: enabling Palo Alto VPN background..."
    sudo "$SCRIPT_DIR/enable-paloalto-launchd.sh" "$CONTEXT_KEY" || exit 1
fi

if [ ! -f "$SSH_KEY" ]; then
    echo "Error: SSH key not found at $SSH_KEY"
    exit 1
fi

echo "Connecting to HPCC RedRaider..."
ssh -i "$SSH_KEY" -o "AddKeysToAgent=yes" "$HPCC_FULL"
