#!/usr/bin/env bash

#######################################
# Kubernetes interactions
# Used by: main script
#######################################

#######################################
# Fetch pod JSON from Kubernetes
# Arguments:
#   $1 - pod name
#   $2 - namespace
# Returns:
#   Pod JSON on success
#   Exits with error on failure
#######################################

fetch_pod() {
    local pod="$1"
    local namespace="$2"
    local pod_json
    local error_output
    
    log_info "Fetching pod '$pod' from namespace '$namespace'..."
    
    # Try to get pod JSON
    # Capture both stdout and stderr
    if ! pod_json=$(kubectl get pod "$pod" -n "$namespace" -o json 2>/dev/null); then
        log_error "Failed to get pod '$pod' in namespace '$namespace'"
        echo ""
        echo "kubectl output:"
        echo "$pod_json"
        echo ""
        echo "Troubleshooting:"
        echo "  1. Check if pod exists:"
        echo "     kubectl get pods -n $namespace"
        echo ""
        echo "  2. Check if namespace exists:"
        echo "     kubectl get namespaces | grep $namespace"
        echo ""
        echo "  3. Check cluster connection:"
        echo "     kubectl cluster-info"
        exit 1
    fi
    
    log_success "Pod fetched successfully"
    
    # Return JSON
    echo "$pod_json"
}

#######################################
# Extract pod status fields
# Arguments:
#   $1 - pod JSON
# Sets global variables:
#   PHASE - pod phase
#   REASON - pod-level reason (Evicted, etc.) or "Unknown"
#   CRASH_DETAILS - multi-line list of container/init failures (reason, exit code, message)
#######################################

extract_pod_status() {
    local pod_json="$1"
    
    # Extract phase
    PHASE=$(echo "$pod_json" | jq -r '.status.phase // "Unknown"')
    
    # Pod-level reason (set only in cases like Evicted, NodeAffinity, etc.)
    REASON=$(echo "$pod_json" | jq -r '.status.reason // "Unknown"')
    
    # Container-level crash details: terminated, waiting (CrashLoopBackOff → lastState), waiting only
    CRASH_DETAILS=$(echo "$pod_json" | jq -r '
        def line(r; code; msg; suffix):
            (r // "?") +
            (if code != null then " (exit " + (code | tostring) + ")" else "" end) +
            (if (msg // "") | length > 0 then " — " + msg else "" end) +
            (if (suffix // "") | length > 0 then " [" + suffix + "]" else "" end);
        def add(t; n; r; code; msg; suffix): (t + " \"" + n + "\": " + line(r; code; msg; suffix));
        [
            (.status.initContainerStatuses[]? | {t: "Init container", n: .name, term: .state.terminated, wait: .state.waiting, last: .lastState.terminated}),
            (.status.containerStatuses[]? | {t: "Container", n: .name, term: .state.terminated, wait: .state.waiting, last: .lastState.terminated})
        ] | map(
            if .term then add(.t; .n; .term.reason; .term.exitCode; .term.message; null)
            elif .wait != null and .last != null then add(.t; .n; .last.reason; .last.exitCode; .last.message; .wait.reason)
            elif .wait != null then add(.t; .n; .wait.reason; null; .wait.message; null)
            else empty end
        ) | .[]
    ')
}
