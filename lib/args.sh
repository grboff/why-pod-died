#!/usr/bin/env bash

#######################################
# Argument parsing
#######################################

export POD=""
export NAMESPACE="default"
export LOG_LINES=20  # Default log lines

show_help() {
    cat << HELP
why-pod-died v1.0 - SRE Diagnostic Tool

USAGE:
    why-pod-died POD_NAME [OPTIONS]

OPTIONS:
    -n, --namespace NS    Namespace (default: default)
    -l, --lines N         Number of log lines to show (default: 20)
    -h, --help            Show this help

EXAMPLES:
    why-pod-died my-app
    why-pod-died my-app -n prod -l 50
HELP
}

parse_arguments() {
    POD=""
    NAMESPACE="default"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--namespace)
                NAMESPACE="$2"; shift 2 ;;
            -l|--lines)
                LOG_LINES="$2"; shift 2 ;;
            -h|--help)
                show_help; exit 0 ;;
            -*)
                log_error "Unknown option: $1"; exit 1 ;;
            *)
                if [[ -n "$POD" ]]; then
                    log_error "Multiple pods specified"; exit 1
                fi
                POD="$1"; shift ;;
        esac
    done
    
    if [[ -z "$POD" ]]; then
        log_error "Pod name required"; show_help; exit 1
    fi
}