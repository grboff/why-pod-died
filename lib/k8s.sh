#!/usr/bin/env bash

#######################################
# Kubernetes interactions
#######################################

fetch_pod() {
    local pod="$1"
    local ns="$2"
    local out
    
    log_info "Fetching metadata for '$pod'..."
    if ! out=$(kubectl get pod "$pod" -n "$ns" -o json 2>/dev/null); then
        log_error "Pod not found or access denied."
        exit 1
    fi
    echo "$out"
}

# Fetch Warning events related to the pod
fetch_events() {
    local pod="$1"
    local ns="$2"
    
    # Get events, filter for Warnings, sort by time, take last 5
    kubectl get events -n "$ns" \
        --field-selector involvedObject.name="$pod",type=Warning \
        --sort-by='.lastTimestamp' \
        -o custom-columns=TIME:.lastTimestamp,MESSAGE:.message \
        | tail -n 5 || true
}

# Fetch logs intelligently (current or previous instance)
fetch_logs() {
    local pod="$1"
    local ns="$2"
    local container="$3"
    local use_previous="$4"
    local lines="$5"

    local opts="--tail=$lines"
    if [[ "$use_previous" == "true" ]]; then
        opts="$opts --previous"
        echo -e "${YELLOW}(Showing logs from PREVIOUS crashed instance)${NC}"
    else
        echo -e "${GREEN}(Showing logs from terminated container)${NC}"
    fi

    kubectl logs "$pod" -n "$ns" -c "$container" $opts 2>&1 || echo "No logs found."
}

# Analyze pod and extract actionable data
analyze_pod() {
    local json="$1"

    # Basic Info
    PHASE=$(echo "$json" | jq -r '.status.phase // "Unknown"')
    REASON=$(echo "$json" | jq -r '.status.reason // "None"')
    START_TIME=$(echo "$json" | jq -r '.status.startTime // "Unknown"')

    # Find the "worst" container (the one causing the crash)
    # We construct a JSON object describing the bad container and print it compact (-c)
    BAD_CONTAINER_INFO=$(echo "$json" | jq -c '
        ([.status.initContainerStatuses[]?], [.status.containerStatuses[]?]) | flatten | 
        map(select(. != null)) | 
        map(
            if .state.terminated.exitCode != 0 and .state.terminated.exitCode != null then
                {name: .name, state: "terminated", reason: .state.terminated.reason, code: .state.terminated.exitCode, msg: .state.terminated.message, is_bad: true, use_prev: false}
            elif .lastState.terminated.exitCode != 0 and .lastState.terminated.exitCode != null then
                {name: .name, state: "crashloop", reason: .lastState.terminated.reason, code: .lastState.terminated.exitCode, msg: .lastState.terminated.message, is_bad: true, use_prev: true}
            elif .state.waiting.reason == "ImagePullBackOff" or .state.waiting.reason == "ErrImagePull" or .state.waiting.reason == "CrashLoopBackOff" then
                {name: .name, state: "waiting", reason: .state.waiting.reason, code: 0, msg: .state.waiting.message, is_bad: true, use_prev: false}
            else
                {name: .name, is_bad: false}
            end
        ) | 
        sort_by(.is_bad) | reverse | .[0]
    ')
}