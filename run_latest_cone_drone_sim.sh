#!/usr/bin/env bash

# recommended error handling
set -euo pipefail

# Find the most recent file matching the pattern
latest_file=$(ls -t cone_drone_sim_* 2>/dev/null | head -n 1)

if [[ -z "${latest_file:-}" ]]; then
    echo "No files matching pattern 'cone_drone_sim_*' found."
    exit 1
fi

echo "Running: $latest_file"
./"$latest_file"
