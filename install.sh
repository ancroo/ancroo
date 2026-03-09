#!/bin/bash
# ancroo/install.sh — Bootstrapper for the Ancroo AI Stack
#
# Clones all required repositories and delegates to ancroo-stack/install.sh
# for the actual installation. If repos already exist, skips cloning.
#
# Usage:
#   bash install.sh           # interactive
#   bash install.sh --dev     # build from source (dev mode)
set -euo pipefail

# ─── Minimal output helpers (before ancroo-stack is available) ───
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
print_success() { echo -e "  ${GREEN}✓${NC} $1"; }
print_info()    { echo -e "  ${CYAN}→${NC} $1"; }
print_warning() { echo -e "  ${YELLOW}⚠${NC} $1"; }
print_error()   { echo -e "  ${RED}✗${NC} $1"; }

# ─── Paths ───────────────────────────────────────────────
INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$INSTALLER_DIR/.." && pwd)"
STACK_DIR="${WORKSPACE_ROOT}/ancroo-stack"
BACKEND_DIR="${WORKSPACE_ROOT}/ancroo-backend"
RUNNER_DIR="${WORKSPACE_ROOT}/ancroo-runner"
WEB_DIR="${WORKSPACE_ROOT}/ancroo-web"

STACK_REPO="https://github.com/ancroo/ancroo-stack.git"
BACKEND_REPO="https://github.com/ancroo/ancroo-backend.git"
RUNNER_REPO="https://github.com/ancroo/ancroo-runner.git"
WEB_REPO="https://github.com/ancroo/ancroo-web.git"

# ─── Pre-flight ──────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Ancroo — Bootstrapper${NC}"
echo ""

if ! command -v git &>/dev/null; then
    print_error "git is not installed"
    exit 1
fi
print_success "git available"

if ! command -v docker &>/dev/null; then
    print_error "Docker is not installed"
    print_info "Install: https://docs.docker.com/engine/install/"
    exit 1
fi
print_success "Docker available"

# ─── Clone repositories ─────────────────────────────────
echo ""
echo -e "  ${BOLD}Cloning repositories${NC}"
echo ""

CLONE_FAILURES=0

clone_or_skip() {
    local dir="$1" repo="$2" name="$3"
    if [[ -d "$dir/.git" ]]; then
        print_info "${name}: already present, skipping"
    elif [[ -d "$dir" ]]; then
        print_info "${name}: directory exists but is not a git repo — skipping"
    else
        echo -ne "  Cloning ${name}... "
        if git clone "$repo" "$dir" 2>/dev/null; then
            echo -e "${GREEN}done${NC}"
        else
            echo -e "${RED}failed${NC}"
            print_error "${name}: clone failed — check your access to ${repo}"
            CLONE_FAILURES=$((CLONE_FAILURES + 1))
        fi
    fi
}

clone_or_skip "$STACK_DIR"   "$STACK_REPO"   "ancroo-stack"
clone_or_skip "$BACKEND_DIR" "$BACKEND_REPO" "ancroo-backend"
clone_or_skip "$RUNNER_DIR"  "$RUNNER_REPO"  "ancroo-runner"
clone_or_skip "$WEB_DIR"     "$WEB_REPO"     "ancroo-web"

if [[ $CLONE_FAILURES -gt 0 ]]; then
    echo ""
    print_warning "${CLONE_FAILURES} repository(s) could not be cloned"
    print_info "If the repos are private, make sure you have access:"
    print_info "  gh auth login        (GitHub CLI)"
    print_info "  gh auth setup-git    (configure git credentials)"
    echo ""
fi

# ancroo-stack is required — backend and extension are optional
if [[ ! -d "$STACK_DIR" ]]; then
    print_error "ancroo-stack could not be cloned — cannot continue"
    exit 1
fi

# ─── Hand off to ancroo-stack installer ──────────────────

# When stdin is not a terminal (e.g. piped or scripted context),
# enable non-interactive mode to prevent the stack installer's
# interactive prompts from consuming stdin unexpectedly.
if [[ ! -t 0 ]]; then
    export ANCROO_NONINTERACTIVE=1
    print_info "Non-interactive mode (stdin is not a terminal)"
fi

echo ""
print_info "Starting Ancroo Stack installer..."
echo ""
exec bash "$STACK_DIR/install.sh" "$@"
