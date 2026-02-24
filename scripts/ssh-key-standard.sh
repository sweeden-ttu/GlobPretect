#!/bin/bash
# ssh-key-standard.sh - Standard SSH key naming and HPCC context (source this in other scripts)
#
# SSH key identity is ALWAYS named using FOUR factors (stored in ~/.ssh, never in project):
#   1. Current logged-in user ($USER) - must NOT be root
#   2. Current machine name ($HOSTNAME) - must NOT be the remote cluster name
#   3. Remote cluster name: "hpcc" (login.hpcc.ttu.edu) or "github" (github.com)
#   4. Remote username: "sweeden" (hpcc) or "sweeden-ttu" (github)
#
# Key path: ~/.ssh/id_ed25519_${USER}_${HOSTNAME}_${REMOTE_CLUSTER}_${REMOTE_USER}
#
# When hostname matches login*, gpu*-*, or cpu*-* (e.g. login20-2, gpu2-12, cpu8-1),
# the current machine is already on the HPCC cluster. When hostname begins with "login",
# one more step is required to reserve compute resources (interactive or non-interactive).

# Normalize hostname (short name, no domain)
_ssh_std_hostname="${HOSTNAME%%.*}"

# Return 0 if we are on an HPCC node (login, gpu, or cpu)
ssh_std_on_hpcc() {
    [[ "$_ssh_std_hostname" == login* ]] || \
    [[ "$_ssh_std_hostname" == gpu*-* ]] || \
    [[ "$_ssh_std_hostname" == cpu*-* ]]
}

# Return 0 if we are on an HPCC login node (need to reserve resources)
ssh_std_on_hpcc_login() {
    [[ "$_ssh_std_hostname" == login* ]]
}

# Set SSH key path for a given remote. Usage: ssh_std_set_key "hpcc" | "github"
# Exports: SSH_KEY, REMOTE_USER, REMOTE_CLUSTER
ssh_std_set_key() {
    local remote_cluster="${1:-hpcc}"
    if [[ "$(id -u)" -eq 0 ]]; then
        echo "Error: Do not run as root. SSH key identity requires a non-root user." >&2
        return 1
    fi
    if [[ "$remote_cluster" == "hpcc" ]]; then
        REMOTE_CLUSTER="hpcc"
        REMOTE_USER="sweeden"
    elif [[ "$remote_cluster" == "github" ]]; then
        REMOTE_CLUSTER="github"
        REMOTE_USER="sweeden-ttu"
    else
        echo "Error: remote_cluster must be 'hpcc' or 'github'" >&2
        return 1
    fi
    # Current machine name must not be used as remote cluster identifier
    export REMOTE_CLUSTER REMOTE_USER
    export SSH_KEY="$HOME/.ssh/id_ed25519_${USER}_${_ssh_std_hostname}_${REMOTE_CLUSTER}_${REMOTE_USER}"
}

# HPCC: reserve resources when on login node (interactive). Call after detecting login* hostname.
# Option 1: Interactive - run Slurm interactive script, wait, verify hostname changed to gpu*-* or cpu*-*
ssh_std_hpcc_reserve_interactive() {
    if ! ssh_std_on_hpcc_login; then
        return 0
    fi
    if [[ -x /etc/slurm/scripts/interactive ]]; then
        echo "On HPCC login node. Starting interactive resource reservation..."
        /etc/slurm/scripts/interactive
        echo "Waiting 60s for allocation..."
        sleep 60
        local new_host="${HOSTNAME%%.*}"
        if [[ "$new_host" == gpu*-* ]] || [[ "$new_host" == cpu*-* ]]; then
            echo "Allocation ready. Hostname: $new_host"
        else
            echo "Warning: Hostname still $new_host. Expected gpu*-* or cpu*-*."
        fi
    else
        echo "Warning: /etc/slurm/scripts/interactive not found. Use non-interactive (squeue, sinfo, scancel)."
    fi
}

# HPCC non-interactive: print commands for job-based reservation
# squeue -u sweeden; scancel <jobID> to cancel; sinfo (partition matador, GPU modules); OLLAMA_MODEL_$JOBID="$PORT":"$MODEL"
ssh_std_hpcc_reserve_noninteractive_help() {
    echo "HPCC non-interactive reservation:"
    echo "  squeue -u sweeden           # list your jobs"
    echo "  scancel <jobID>             # cancel Ollama job"
    echo "  sinfo                       # verify partition (matador), GPU modules loaded, find JOBID"
    echo "  OLLAMA_MODEL_\$JOBID=\"\$PORT\":\"\$MODEL\"  # set port-to-model for this job"
    echo "Valid port-to-model (production): 55077=granite4, 55088=deepseek-r1, 66044=qwen-coder, 66033=codellama"
    echo "Valid port-to-model (testing):   55177=granite4, 55188=deepseek-r1, 66144=qwen-coder, 66133=codellama"
}
