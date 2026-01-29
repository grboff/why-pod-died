#!/usr/bin/env bash
set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load libraries
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/args.sh"
source "$SCRIPT_DIR/lib/k8s.sh"

main() {
    check_dependencies
    parse_arguments "$@"
    
    # 1. Fetch Data
    POD_JSON=$(fetch_pod "$POD" "$NAMESPACE")
    analyze_pod "$POD_JSON" # Sets BAD_CONTAINER_INFO (raw json string)
    
    # Extract fields directly from the JSON string
    local c_name=$(echo "$BAD_CONTAINER_INFO" | jq -r '.name // empty')
    local c_reason=$(echo "$BAD_CONTAINER_INFO" | jq -r '.reason // "Unknown"')
    local c_code=$(echo "$BAD_CONTAINER_INFO" | jq -r '.code // 0')
    local c_msg=$(echo "$BAD_CONTAINER_INFO" | jq -r '.msg // ""')
    local use_prev=$(echo "$BAD_CONTAINER_INFO" | jq -r '.use_prev')
    local is_bad=$(echo "$BAD_CONTAINER_INFO" | jq -r '.is_bad')

    # 2. Print Summary
    print_header "🚨 DIAGNOSTICS: $POD"
    echo "Namespace:  $NAMESPACE"
    echo "Phase:      $PHASE"
    
    # LOGIC FIX: Check both container status AND Pod Phase
    if [[ "$c_reason" == "OOMKilled" ]]; then
         echo -e "Status:     ${RED}${BOLD}OOMKilled (Out Of Memory)${NC}"
    elif [[ "$is_bad" == "true" ]]; then
         echo -e "Status:     ${RED}Failed${NC} (Exit Code: $c_code)"
         echo "Reason:     $c_reason"
    elif [[ "$PHASE" == "Failed" ]]; then
         # Fallback for pods that just exited (like your busybox test)
         echo -e "Status:     ${RED}Pod Failed${NC} (Containers terminated)"
         is_bad="true" # Force logs to show
         c_name=$(echo "$POD_JSON" | jq -r '.spec.containers[0].name') # Guess first container
    else
         echo -e "Status:     ${GREEN}Running / Healthy${NC}"
    fi

    if [[ -n "$c_msg" && "$c_msg" != "null" ]]; then
        echo "Message:    $c_msg"
    fi

    # 3. Print Events
    print_subheader "🔍 RECENT WARNING EVENTS"
    local events=$(fetch_events "$POD" "$NAMESPACE")
    if [[ -z "$events" ]]; then
        echo "No recent warning events found."
    else
        echo "$events"
    fi

    # 4. Print Logs
    # Show logs if container is bad OR if Phase is Failed
    if [[ "$is_bad" == "true" || "$PHASE" == "Failed" ]]; then
        print_subheader "📜 LOGS (Container: $c_name)"
        fetch_logs "$POD" "$NAMESPACE" "$c_name" "$use_prev" "$LOG_LINES"
        
        print_header "✅ SUGGESTION"
        if [[ "$c_reason" == "OOMKilled" ]]; then
            echo "👉 Increase 'limits.memory' in your deployment YAML."
        elif [[ "$c_code" == "137" ]]; then
            echo "👉 Container received SIGKILL (likely OOM or Liveness Probe failure)."
        elif [[ "$c_code" == "1" ]]; then
            echo "👉 Application error. Check the stack trace in the logs above."
        elif [[ "$c_reason" == "ImagePullBackOff" ]]; then
            echo "👉 Check image name, tag, and registry credentials."
        else
            echo "👉 Check logs above. Pod exited with error."
        fi
    else
        echo ""
        echo "Pod seems healthy. If it's not working, check Service/Ingress."
    fi
}

main "$@"