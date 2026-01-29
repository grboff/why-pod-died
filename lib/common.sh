#!/usr/bin/env bash

#######################################
# Common utilities
# Used by: all scripts
#######################################

#######################################
# Colors
#######################################
export RED='\033[0;31m'
export YELLOW='\033[1;33m'
export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export NC='\033[0m'  # No Color

#######################################
# Logging functions
#######################################
#вывести в stderr
log_error() {
    echo -e "${RED}ERROR:${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}WARNING:${NC} $1" >&2
}

log_info() {
    echo -e "${BLUE}INFO:${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}✓${NC} $1" >&2
}

#######################################
# Dependency checking
#######################################

check_dependencies() {
    local missing=()
    
    # Check jq
    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        missing+=("kubectl")
    fi
    
    # If something is missing - show error and exit
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        echo ""
        echo "Install instructions:"
        
        for dep in "${missing[@]}"; do
            case "$dep" in
                jq)
                    echo "  jq:"
                    echo "    macOS:  brew install jq"
                    echo "    Ubuntu: sudo apt-get install jq"
                    echo "    CentOS: sudo yum install jq"
                    ;;
                kubectl)
                    echo "  kubectl:"
                    echo "    https://kubernetes.io/docs/tasks/tools/"
                    ;;
            esac
        done
        
        exit 1
    fi
}
