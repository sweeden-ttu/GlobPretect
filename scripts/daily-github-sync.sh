#!/bin/bash
# daily-github-sync.sh - Sync all projects under PROJECTS_DIR with GitHub
#
# Accepts one of the 20 context keys (CONTEXT_KEY or first arg). Decision: only run sync when key receiver is GitHub (*_github_*).
# SSH key is chosen from the key (owner_github, quay_github, or hpcc_github). Run once: gh auth setup-git
#
# Steps per repo (and recursively for submodules):
#   1. Commit unsaved changes; add untracked files
#   2. Fetch/pull and automatically merge all changes that can be merged
#   3. Push to default branch (defaultBranch set consistently)
#   4. If push fails, create a new branch and open a pull request
#   5. Sync recursively all projects and submodules

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# For sync: CONTEXT_KEY = second arg or env. For setup/install-hooks: optional key for context.
CONTEXT_KEY="${2:-$CONTEXT_KEY}"
if [[ "${1:-sync}" == "sync" ]]; then
    # shellcheck source=./context-key.sh
    source "$SCRIPT_DIR/context-key.sh"
    context_key_require
    # Decision: only sync to GitHub when key receiver is github
    if [[ "$CONTEXT_RECEIVER" != "github" ]]; then
        echo "Key $CONTEXT_KEY has receiver $CONTEXT_RECEIVER; daily-github-sync is for GitHub only. Use a *_github_* key." >&2
        exit 1
    fi
    GITHUB_SSH_KEY_IDENTIFIER="${SSH_KEY_IDENTIFIER}"
else
    # setup | install-hooks: key optional; default SSH key for GitHub
    if [[ -n "$CONTEXT_KEY" ]] && [[ -f "$SCRIPT_DIR/context-key.sh" ]]; then
        source "$SCRIPT_DIR/context-key.sh"
        context_key_valid "$CONTEXT_KEY" 2>/dev/null && context_key_parse "$CONTEXT_KEY" 2>/dev/null && GITHUB_SSH_KEY_IDENTIFIER="${SSH_KEY_IDENTIFIER}" || true
    fi
    GITHUB_SSH_KEY_IDENTIFIER="${GITHUB_SSH_KEY_IDENTIFIER:-owner_owner_sweeden-ttu_github}"
fi
SSH_KEY="$HOME/.ssh/id_ed25519_${GITHUB_SSH_KEY_IDENTIFIER}"
export GIT_SSH_COMMAND="ssh -i \"$SSH_KEY\" -o IdentitiesOnly=yes"

# Configuration
GIT_EMAIL="sweeden@ttu.edu"
GIT_NAME="sweeden-ttu"
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"

# All repos: every directory under PROJECTS_DIR that has a .git
REPOS=()
if [[ -d "$PROJECTS_DIR" ]]; then
    for d in "$PROJECTS_DIR"/*/; do
        [[ -d "${d}.git" ]] && REPOS+=("$(basename "$d")")
    done
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Ensure GitHub CLI uses SSH for git
setup_gh_git() {
    if command -v gh &>/dev/null; then
        log_info "Configuring git to use SSH via GitHub CLI..."
        gh auth setup-git 2>/dev/null || log_warn "gh auth setup-git failed (run manually if needed)"
    fi
}

# Set consistent default branch for a repo
set_default_branch() {
    local dir="$1"
    (cd "$dir" && git config init.defaultBranch "$DEFAULT_BRANCH" 2>/dev/null || true)
}

# Get current default branch (origin/HEAD, then origin/main/master, else DEFAULT_BRANCH)
get_default_branch() {
    local dir="$1"
    local branch
    branch=$(cd "$dir" && git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|^refs/remotes/origin/||') || true
    if [[ -z "$branch" ]]; then
        (cd "$dir" && git show-ref --verify refs/remotes/origin/main &>/dev/null) && branch=main
        [[ -z "$branch" ]] && (cd "$dir" && git show-ref --verify refs/remotes/origin/master &>/dev/null) && branch=master
    fi
    echo "${branch:-$DEFAULT_BRANCH}"
}

# Build standard commit message for CI/CD: @cursor @gemini @claude @actions-user + task list.
# See docs/COMMIT_MESSAGE_STANDARD.md. Optional first arg = subject line.
build_commit_message() {
    local subject="${1:-Daily sync $(date +%Y-%m-%d)}"
    echo "$subject"
    echo ""
    echo "Review: @cursor @gemini @claude @actions-user"
    echo "Refs: CURSOR.md GEMINI.md CLAUDE.md AGENTS.md"
    echo ""
    echo "Tasks:"
    echo "- @macos @maclaptop: run daily-github-sync; verify VPN/GlobPretect if needed"
    echo "- @rockylinux @rockydesktop: run daily-github-sync if applicable"
    echo "- @hpcc @hpcc-gpu @hpcc-cpu: no action unless HPCC jobs or tunnels changed"
    echo "- @actions-user @github-actions: CI runs on push (see .github/workflows)"
}

# Step 1: Commit unsaved changes and add untracked files (standard CI/CD message)
commit_all_changes() {
    local repo="$1"
    local dir="$2"
    local subject="${3:-Daily sync $(date +%Y-%m-%d)}"
    (cd "$dir" && git add -A && git status --short) | grep -q . || return 0
    local msg
    msg=$(build_commit_message "$subject")
    (cd "$dir" && git commit -m "$subject" \
        -m "Review: @cursor @gemini @claude @actions-user" \
        -m "Refs: CURSOR.md GEMINI.md CLAUDE.md AGENTS.md" \
        -m "Tasks:" \
        -m "- @macos @maclaptop: run daily-github-sync; verify VPN/GlobPretect if needed" \
        -m "- @rockylinux @rockydesktop: run daily-github-sync if applicable" \
        -m "- @hpcc @hpcc-gpu @hpcc-cpu: no action unless HPCC jobs or tunnels changed" \
        -m "- @actions-user @github-actions: CI runs on push (see .github/workflows)") && log_info "$repo: Committed changes" || true
}

# Step 5 (inner): Update submodules recursively
sync_submodules() {
    local dir="$1"
    local repo_name="$2"
    if [[ ! -f "$dir/.gitmodules" ]]; then
        return 0
    fi
    (cd "$dir" && git submodule update --init --recursive) && log_info "$repo_name: Submodules updated" || true
}

# After merge: if @macbook or @rockydesktop in merged commits, run on-macbook-comment (local .githooks or core.hooksPath)
run_macbook_comment_hook_if_needed() {
    local dir="$1"
    local repo_name="$2"
    (cd "$dir" && git rev-parse -q --verify ORIG_HEAD >/dev/null 2>&1) || return 0
    local merged_msgs
    merged_msgs=$(cd "$dir" && git log ORIG_HEAD..HEAD --format=%B 2>/dev/null)
    echo "$merged_msgs" | grep -qE '@macbook|@rockydesktop' || return 0
    local handler="$dir/.githooks/on-macbook-comment"
    local hooks_path
    hooks_path=$(cd "$dir" && git config --get core.hooksPath 2>/dev/null) || true
    if [[ -n "$hooks_path" && ! -x "$handler" ]]; then
        if [[ "$hooks_path" != /* ]]; then
            hooks_path="$dir/$hooks_path"
        fi
        handler="$hooks_path/on-macbook-comment"
    fi
    if [[ -x "$handler" ]]; then
        log_info "$repo_name: @macbook/@rockydesktop in merged commits; running on-macbook-comment"
        (cd "$dir" && "$handler" "$dir" "$merged_msgs") || true
    fi
}

# Step 2: Fetch and pull (merge) — integrate remote changes that can be merged
fetch_and_merge() {
    local dir="$1"
    local branch="$2"
    local repo_name="$3"
    (cd "$dir" && git fetch origin 2>/dev/null) || return 0
    if (cd "$dir" && git merge "origin/$branch" --no-edit 2>/dev/null); then
        log_info "$repo_name: Merged origin/$branch"
        run_macbook_comment_hook_if_needed "$dir" "$repo_name"
    else
        (cd "$dir" && git merge --abort 2>/dev/null) || true
        log_warn "$repo_name: Merge had conflicts; resolve manually"
    fi
}

# Step 3 & 4: Push to default branch; on failure create branch and open PR
push_or_pr() {
    local repo="$1"
    local dir="$2"
    local branch="$3"
    if (cd "$dir" && git push origin "$branch" 2>/dev/null); then
        log_info "$repo: Pushed to origin/$branch"
        return 0
    fi
    log_warn "$repo: Push to $branch failed; creating branch and PR..."
    local pr_branch="daily-sync-$(date +%Y%m%d-%H%M)"
    (cd "$dir" && git checkout -b "$pr_branch" 2>/dev/null) || (cd "$dir" && git checkout "$pr_branch" 2>/dev/null) || true
    if ! (cd "$dir" && git push -u origin "$pr_branch" 2>/dev/null); then
        log_error "$repo: Failed to push branch $pr_branch"
        (cd "$dir" && git checkout "$branch" 2>/dev/null) || true
        return 1
    fi
    if command -v gh &>/dev/null; then
        (cd "$dir" && gh pr create --base "$branch" --head "$pr_branch" --title "Daily sync: $pr_branch" --body "Auto sync from daily-github-sync.sh" 2>/dev/null) && log_info "$repo: PR created" || log_warn "$repo: Pushed $pr_branch; create PR manually if needed"
    else
        log_warn "$repo: Pushed $pr_branch; run 'gh pr create' manually if needed"
    fi
    (cd "$dir" && git checkout "$branch" 2>/dev/null) || true
}

# Full sync for one repo (and its submodules recursively)
sync_one_repo() {
    local repo="$1"
    local dir="$PROJECTS_DIR/$repo"
    if [[ ! -d "$dir/.git" ]]; then
        log_error "Not a git repo: $dir"
        return 1
    fi
    echo ""
    log_info "=== Syncing $repo ==="
    set_default_branch "$dir"
    local branch
    branch=$(get_default_branch "$dir")
    # 1. Commit local changes and untracked
    commit_all_changes "$repo" "$dir" "Daily sync $(date +%Y-%m-%d)"
    # 5. Submodules init/update (before pull so we have full tree)
    sync_submodules "$dir" "$repo"
    # 2. Fetch and merge
    fetch_and_merge "$dir" "$branch" "$repo"
    # 3 & 4. Push or create PR
    push_or_pr "$repo" "$dir" "$branch"
    # 5. Sync submodules recursively (commit and push submodule changes if any)
    if [[ -f "$dir/.gitmodules" ]]; then
        (cd "$dir" && git submodule foreach --recursive 'git add -A; git diff --cached --quiet || git commit -m "Daily sync" || true; git push origin HEAD 2>/dev/null || true') || true
    fi
    log_info "=== $repo sync complete ==="
}

# Configure git globally
configure_git() {
    git config --global user.email "$GIT_EMAIL" 2>/dev/null || true
    git config --global user.name "$GIT_NAME" 2>/dev/null || true
    git config --global init.defaultBranch "$DEFAULT_BRANCH" 2>/dev/null || true
    git config --global url."git@github.com:".insteadOf "https://github.com/" 2>/dev/null || true
}

main() {
    log_info "Daily GitHub sync (SSH key: $GITHUB_SSH_KEY_IDENTIFIER, default branch: $DEFAULT_BRANCH)"
    if [[ ! -f "$SSH_KEY" ]]; then
        log_error "SSH key not found: $SSH_KEY"
        exit 1
    fi
    configure_git
    setup_gh_git
    for repo in "${REPOS[@]}"; do
        sync_one_repo "$repo" || log_error "Sync failed: $repo"
    done
    log_info "Daily GitHub sync complete."
}

case "${1:-sync}" in
    sync)   main ;;
    setup)  setup_gh_git; configure_git; log_info "Run 'gh auth login' and 'gh auth setup-git' if needed." ;;
    install-hooks)
        CONTEXT_KEY="$CONTEXT_KEY" PROJECTS_DIR="$PROJECTS_DIR" "$SCRIPT_DIR/install-git-hooks-all-repos.sh" "$CONTEXT_KEY"
        ;;
    *)
        echo "Usage: $0 sync <context_key>   # key = one of 20 (e.g. owner_github_granite); receiver must be github"
        echo "       $0 setup [context_key]"
        echo "       $0 install-hooks [context_key]"
        echo "       CONTEXT_KEY=<key> $0 sync"
        exit 1
        ;;
esac
