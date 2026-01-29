#!/usr/bin/env bash
set -euo pipefail

#######################################
# why-pod-died v0.2
# Kubernetes pod failure diagnostics
#
# Iteration 2: Modular structure + error handling
#######################################

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load libraries
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/args.sh"
source "$SCRIPT_DIR/lib/k8s.sh"

#######################################
# Main function
#######################################

main() {
    # 1. Check dependencies
    check_dependencies
    
    # 2. Parse arguments
    parse_arguments "$@"
    
    # 3. Fetch pod from Kubernetes
    POD_JSON=$(fetch_pod "$POD" "$NAMESPACE")
    
    # 4. Extract status
    extract_pod_status "$POD_JSON"
    
    # 5. Display results
    echo "================================"
    echo "Pod: $POD"
    echo "Namespace: $NAMESPACE"
    echo "Phase: $PHASE"
    echo "Reason: $REASON"
    if [[ -n "${CRASH_DETAILS:-}" ]]; then
        echo "--------------------------------"
        echo "Why it failed:"
        echo "$CRASH_DETAILS"
    fi
    echo "================================"
}

# Run main
main "$@"
