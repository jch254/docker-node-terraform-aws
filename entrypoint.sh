#!/bin/bash

# CodeBuild-optimized entrypoint script
# Handles proper signal forwarding and process management

set -e

# Function to handle signals and cleanup
cleanup() {
    echo "Cleaning up..."
    # Kill any background processes
    jobs -p | xargs -r kill
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# If no command provided, start an interactive shell
if [ $# -eq 0 ]; then
    echo "Starting interactive shell..."
    exec /bin/bash
else
    # If it's a single string command with shell operators, execute with bash -c
    if [ $# -eq 1 ] && [[ "$1" == *"&&"* || "$1" == *"||"* || "$1" == *"|"* || "$1" == *";"* ]]; then
        echo "Executing shell command: $1"
        exec /bin/bash -c "$1"
    else
        # Execute the provided command directly
        echo "Executing: $*"
        exec "$@"
    fi
fi
