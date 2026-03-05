#!/bin/bash
# common.sh — Shared helpers for ancroo install scripts

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "  ${BOLD}${BLUE}════════════════════════════════════════════════${NC}"
    echo -e "  ${BOLD}${BLUE}  $1${NC}"
    echo -e "  ${BOLD}${BLUE}════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo ""
    echo -e "  ${BOLD}▸ $1${NC}"
}

print_success() { echo -e "  ${GREEN}✓${NC}  $1"; }
print_info()    { echo -e "  ${CYAN}→${NC}  $1"; }
print_warning() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
print_error()   { echo -e "  ${RED}✗${NC}  $1"; }

confirm() {
    local prompt="$1"
    local default="${2:-y}"
    local hint="[Y/n]"
    [[ "$default" == "n" ]] && hint="[y/N]"
    echo -ne "  ${prompt} ${hint}: " >&2
    read -r answer
    answer="${answer:-$default}"
    [[ "$answer" =~ ^[Yy] ]]
}

prompt_input() {
    local prompt="$1"
    local default="${2:-}"
    local is_secret="${3:-false}"
    local result

    if [[ "$is_secret" == "true" ]]; then
        echo -ne "  ${prompt}: " >&2
        read -rs result
        echo "" >&2
    elif [[ -n "$default" ]]; then
        echo -ne "  ${prompt} [${default}]: " >&2
        read -r result
        result="${result:-$default}"
    else
        echo -ne "  ${prompt}: " >&2
        read -r result
    fi

    echo "$result"
}

# Read a value from a .env file
read_env_value() {
    local key="$1"
    local file="${2:-}"
    [[ -f "$file" ]] && grep "^${key}=" "$file" | head -1 | sed 's/^[^=]*=//;s/^"//;s/"$//' || true
}
