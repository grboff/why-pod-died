#!/usr/bin/env bash
POD=$1
POD_JSON=$(kubectl get pod "$POD" -o json)
PHASE=$(echo "$POD_JSON" | jq -r '.status.phase')
REASON=$(echo "$POD_JSON" | jq -r '.status.reason // "Unknown"')

echo "Pod: $POD"
echo "Phase: $PHASE"
echo "Reason: $REASON"
