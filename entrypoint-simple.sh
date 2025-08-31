#!/bin/bash

# Minimal CodeBuild-compatible entrypoint
# CodeBuild expects containers to handle commands directly without complex processing

# Handle signals properly for CodeBuild
trap 'exit 0' SIGTERM SIGINT

# If no arguments, start bash
if [ $# -eq 0 ]; then
    exec /bin/bash
else
    # Execute the command directly
    exec "$@"
fi
