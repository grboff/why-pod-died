#!/usr/bin/env bash

#######################################
# Common utilities
#######################################

# Colors & Formatting
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export BOLD='\033[1m'
export NC='\033[0m' # No Color

# Logging
log_error()   { echo -e "${RED}ERROR:${NC} $1" >&2; }
log_warn()    { echo -e "${YELLOW}WARNING:${NC} $1" >&2; }
log_info()    { echo -e "${BLUE}INFO:${NC} $1" >&2; }
log_success() { echo -e "${GREEN}✓${NC} $1" >&2; }

# Section Headers
print_header() {
    echo -e "\n${BOLD}==================================================${NC}"
    echo -e "${BOLD}$1${NC}"
    echo -e "${BOLD}==================================================${NC}"
}

print_subheader() {
    echo -e "${BLUE}--------------------------------------------------${NC}"
    echo -e "${BOLD}$1${NC}"
    echo -e "${BLUE}--------------------------------------------------${NC}"
}

# Dependency checking
check_dependencies() {
    local missing=()
    for cmd in jq kubectl; do
        if ! command -v $cmd &> /dev/null; then missing+=("$cmd"); fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        exit 1
    fi
}