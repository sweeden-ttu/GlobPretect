#!/bin/bash
# context-key.sh - Parse and validate one of the 20 context keys (see docs/CONTEXT_KEYS.md).
# Source this in other scripts; then require CONTEXT_KEY (env or $1) and make decisions from it.
#
# Usage: source context-key.sh; context_key_require "owner_hpcc_granite"  # or from $1 / $CONTEXT_KEY

# The 20 valid keys: {owner_hpcc|owner_github|hpcc_github|quay_hpcc|quay_github}_{granite|deepseek|qwen|codellama}
CONTEXT_KEYS_20=(
    owner_hpcc_granite owner_hpcc_deepseek owner_hpcc_qwen owner_hpcc_codellama
    owner_github_granite owner_github_deepseek owner_github_qwen owner_github_codellama
    hpcc_github_granite hpcc_github_deepseek hpcc_github_qwen hpcc_github_codellama
    quay_hpcc_granite quay_hpcc_deepseek quay_hpcc_qwen quay_hpcc_codellama
    quay_github_granite quay_github_deepseek quay_github_qwen quay_github_codellama
)

# Production ports: granite 55077, deepseek 55088, qwen 66044, codellama 66033
context_key_port_for_model() {
    case "$1" in
        granite)   echo 55077 ;;
        deepseek)  echo 55088 ;;
        qwen)      echo 66044 ;;
        codellama) echo 66033 ;;
        *)         echo "" ;;
    esac
}

# Key -> full SSH_KEY_IDENTIFIER (for ~/.ssh/id_ed25519_*)
context_key_to_ssh_identifier() {
    local env="$1"
    case "$env" in
        owner_hpcc)   echo "owner_owner_sweeden_hpcc" ;;
        owner_github) echo "owner_owner_sweeden-ttu_github" ;;
        hpcc_github)  echo "sweeden_hpcc_sweeden-ttu_github" ;;
        quay_hpcc)    echo "quay_sdw3098_sweeden_hpcc" ;;
        quay_github)  echo "quay_sdw3098_sweeden-ttu_github" ;;
        *)            echo "" ;;
    esac
}

# Return 0 if key is valid
context_key_valid() {
    local key="${1:-}"
    local k
    for k in "${CONTEXT_KEYS_20[@]}"; do
        [[ "$key" == "$k" ]] && return 0
    done
    return 1
}

# Parse key into CONTEXT_SSH_ENV, CONTEXT_MODEL, CONTEXT_ORIGIN, CONTEXT_RECEIVER, SSH_KEY_IDENTIFIER, OLLAMA_PORT,
# CONTEXT_ACTION_WHERE, CONTEXT_ACTION_CLIENT.
# Call after validating.
# Exports: CONTEXT_KEY, CONTEXT_SSH_ENV, CONTEXT_MODEL, CONTEXT_ORIGIN, CONTEXT_RECEIVER, SSH_KEY_IDENTIFIER, OLLAMA_PORT,
#   CONTEXT_ACTION_WHERE (github | hpcc = where the automated action runs), CONTEXT_ACTION_CLIENT (macbook | rockydesktop | "" = local client for this key).
context_key_parse() {
    local key="${1:-$CONTEXT_KEY}"
    if ! context_key_valid "$key"; then
        echo "context_key_parse: invalid key '$key'" >&2
        return 1
    fi
    export CONTEXT_KEY="$key"
    # key format: {owner_hpcc|owner_github|hpcc_github|quay_hpcc|quay_github}_{granite|deepseek|qwen|codellama}
    if [[ "$key" == owner_hpcc_* ]]; then
        export CONTEXT_SSH_ENV="owner_hpcc"
        export CONTEXT_ORIGIN="owner"
        export CONTEXT_RECEIVER="hpcc"
    elif [[ "$key" == owner_github_* ]]; then
        export CONTEXT_SSH_ENV="owner_github"
        export CONTEXT_ORIGIN="owner"
        export CONTEXT_RECEIVER="github"
    elif [[ "$key" == hpcc_github_* ]]; then
        export CONTEXT_SSH_ENV="hpcc_github"
        export CONTEXT_ORIGIN="hpcc"
        export CONTEXT_RECEIVER="github"
    elif [[ "$key" == quay_hpcc_* ]]; then
        export CONTEXT_SSH_ENV="quay_hpcc"
        export CONTEXT_ORIGIN="quay"
        export CONTEXT_RECEIVER="hpcc"
    elif [[ "$key" == quay_github_* ]]; then
        export CONTEXT_SSH_ENV="quay_github"
        export CONTEXT_ORIGIN="quay"
        export CONTEXT_RECEIVER="github"
    else
        echo "context_key_parse: unknown key '$key'" >&2
        return 1
    fi
    # Where the action runs: github in key → GitHub workflow agent; hpcc in key → HPCC cluster; else local client.
    if [[ "$key" == *github* ]]; then
        export CONTEXT_ACTION_WHERE="github"
    elif [[ "$key" == *hpcc* ]]; then
        export CONTEXT_ACTION_WHERE="hpcc"
    else
        export CONTEXT_ACTION_WHERE=""
    fi
    # Local client for this key: owner → macbook, quay → rockydesktop, hpcc → none (action at cluster).
    if [[ "$CONTEXT_ORIGIN" == "owner" ]]; then
        export CONTEXT_ACTION_CLIENT="macbook"
    elif [[ "$CONTEXT_ORIGIN" == "quay" ]]; then
        export CONTEXT_ACTION_CLIENT="rockydesktop"
    else
        export CONTEXT_ACTION_CLIENT=""
    fi
    if [[ "$key" == *_granite ]]; then
        export CONTEXT_MODEL="granite"
    elif [[ "$key" == *_deepseek ]]; then
        export CONTEXT_MODEL="deepseek"
    elif [[ "$key" == *_qwen ]]; then
        export CONTEXT_MODEL="qwen"
    elif [[ "$key" == *_codellama ]]; then
        export CONTEXT_MODEL="codellama"
    else
        echo "context_key_parse: unknown model in '$key'" >&2
        return 1
    fi
    local ident
    ident=$(context_key_to_ssh_identifier "$CONTEXT_SSH_ENV")
    export SSH_KEY_IDENTIFIER="$ident"
    export OLLAMA_PORT
    OLLAMA_PORT=$(context_key_port_for_model "$CONTEXT_MODEL")
    return 0
}

# Require CONTEXT_KEY from $1 or env; parse and export. Exit 1 if missing/invalid. Print usage if needed.
# Usage: context_key_require   # uses $1 or $CONTEXT_KEY
#        context_key_require "owner_hpcc_granite"
context_key_require() {
    local key="${1:-${CONTEXT_KEY:-}}"
    if [[ -z "$key" ]]; then
        echo "Usage: CONTEXT_KEY=<key> $0 [args...]  OR  $0 <key> [args...]" >&2
        echo "Valid keys (one of 20): ${CONTEXT_KEYS_20[*]}" >&2
        exit 1
    fi
    if ! context_key_valid "$key"; then
        echo "Invalid CONTEXT_KEY: '$key'. Must be one of: ${CONTEXT_KEYS_20[*]}" >&2
        exit 1
    fi
    context_key_parse "$key" || exit 1
}
