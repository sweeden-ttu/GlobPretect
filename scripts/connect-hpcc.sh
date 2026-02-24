#!/bin/bash
# connect-hpcc.sh - Connect to HPCC RedRaider
#
# SSH key: four factors (see ssh-key-standard.sh) - USER, HOSTNAME, remote cluster (hpcc), remote user (sweeden).
# When already on HPCC (hostname login*|gpu*-*|cpu*-*): if hostname begins with "login", reserve resources first.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./ssh-key-standard.sh
source "$SCRIPT_DIR/ssh-key-standard.sh"

HPCC_HOST="login.hpcc.ttu.edu"
ssh_std_set_key "hpcc" || exit 1
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

# Apple Terminal: enable Palo Alto VPN background before connecting
if [ -n "${TERM_PROGRAM:-}" ] && [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
    echo "Apple Terminal detected: enabling Palo Alto VPN background..."
    sudo "$SCRIPT_DIR/enable-paloalto-launchd.sh" || exit 1
fi

if [ ! -f "$SSH_KEY" ]; then
    echo "Error: SSH key not found at $SSH_KEY"
    exit 1
fi

echo "Connecting to HPCC RedRaider..."
ssh -i "$SSH_KEY" -o "AddKeysToAgent=yes" "$HPCC_FULL"
