#!/usr/bin/env bash

#######################################
# Argument parsing
# Used by: main script
#######################################

# Global variables (will be set by parse_arguments)
export POD=""
export NAMESPACE="default"

#######################################
# Show help message
#######################################

show_help() {
    cat << 'HELP'
why-pod-died v0.2 - Kubernetes pod failure diagnostics

USAGE:
    why-pod-died POD_NAME [OPTIONS]

OPTIONS:
    -n, --namespace NAMESPACE   Kubernetes namespace (default: default)
    -h, --help                  Show this help

EXAMPLES:
    # Check pod in default namespace
    why-pod-died test-crash

    # Check pod in custom namespace
    why-pod-died test-crash -n production

    # Namespace can be before pod name
    why-pod-died -n production test-crash
HELP
}

#######################################
# Parse command line arguments
#######################################

parse_arguments() {
    # Reset to defaults
    POD=""
    NAMESPACE="default"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--namespace)
                if [[ -z "$2" ]]; then
                    log_error "Option -n requires an argument"
                    exit 1
                fi
                NAMESPACE="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                echo ""
                show_help
                exit 1
                ;;
            *)
                if [[ -n "$POD" ]]; then
                    log_error "Multiple pod names specified: '$POD' and '$1'"
                    exit 1
                fi
                POD="$1"
                shift
                ;;
        esac
    done
    
    # Validate that pod name was provided
    if [[ -z "$POD" ]]; then
        log_error "Pod name required"
        echo ""
        show_help
        exit 1
    fi
}
