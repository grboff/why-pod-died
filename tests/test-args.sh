#!/usr/bin/env bash

source lib/common.sh
source lib/args.sh

# Test parsing
parse_arguments "$@"

# Show results
echo "Pod: $POD"
echo "Namespace: $NAMESPACE"
