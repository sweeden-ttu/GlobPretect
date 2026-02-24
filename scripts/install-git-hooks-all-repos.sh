#!/bin/bash
# install-git-hooks-all-repos.sh – set up post-merge and on-macbook-comment hooks for every repo under PROJECTS_DIR.
#
# Accepts one of the 20 context keys (CONTEXT_KEY or first arg). Decision: run for any key (all repos get hooks).
# Used for fetch_and_merge: after `git merge`, the post-merge hook runs and, if @macbook or @rockydesktop
# appears in merged commit messages, runs on-macbook-comment. See docs/GIT_HOOKS.md.
#
# Usage:
#   ./install-git-hooks-all-repos.sh <context_key>   or   CONTEXT_KEY=<key> ./install-git-hooks-all-repos.sh
#   PROJECTS_DIR=/path/to/workspace ./install-git-hooks-all-repos.sh <key>

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTEXT_KEY="${1:-$CONTEXT_KEY}"
# shellcheck source=./context-key.sh
source "$SCRIPT_DIR/context-key.sh"
context_key_require
# Shared hooks: .githooks in the repo that contains this script (e.g. GlobPretect)
GITHOOKS_SOURCE="${GITHOOKS_SOURCE:-$SCRIPT_DIR/../.githooks}"
GITHOOKS_SOURCE="$(cd "$GITHOOKS_SOURCE" 2>/dev/null && pwd)" || true
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"

if [[ -z "$GITHOOKS_SOURCE" || ! -d "$GITHOOKS_SOURCE" ]]; then
    echo "[ERROR] Hooks directory not found: $GITHOOKS_SOURCE" >&2
    exit 1
fi

chmod +x "$GITHOOKS_SOURCE/post-merge" 2>/dev/null || true
chmod +x "$GITHOOKS_SOURCE/on-macbook-comment" 2>/dev/null || true

REPOS=()
if [[ -d "$PROJECTS_DIR" ]]; then
    for d in "$PROJECTS_DIR"/*/; do
        [[ -d "${d}.git" ]] && REPOS+=("$(basename "$d")")
    done
fi

for repo in "${REPOS[@]}"; do
    dir="$PROJECTS_DIR/$repo"
    if [[ ! -d "$dir/.git" ]]; then
        continue
    fi
    if [[ "$(cd "$dir" && pwd)" == "$(cd "$SCRIPT_DIR/.." && pwd)" ]]; then
        # This repo is the one that owns .githooks – use relative path
        (cd "$dir" && git config core.hooksPath .githooks) && echo "[OK] $repo: core.hooksPath = .githooks" || echo "[WARN] $repo: failed to set hooksPath"
    else
        # Other repos – use absolute path to shared hooks
        (cd "$dir" && git config core.hooksPath "$GITHOOKS_SOURCE") && echo "[OK] $repo: core.hooksPath = $GITHOOKS_SOURCE" || echo "[WARN] $repo: failed to set hooksPath"
    fi
done

echo "Git hooks installed for ${#REPOS[@]} repo(s) (context key: $CONTEXT_KEY). Post-merge (and on-macbook-comment) will run after fetch_and_merge. See docs/GIT_HOOKS.md."
