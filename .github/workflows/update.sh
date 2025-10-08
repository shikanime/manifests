#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

for workflow in "$(dirname "$0")"/*.{yml,yaml}; do
  echo "Checking $workflow for updates..."
  if [[ -f $workflow ]]; then
    # Extract action versions and check for updates
    grep -E "uses: [^@]+@[^/]+" "$workflow" | while read -r line; do
      action=$(echo "$line" | grep -oE "uses: [^@]+" | cut -d' ' -f2)
      current_version=$(echo "$line" | grep -oE "@[^[:space:]]+" | cut -d'@' -f2)

      # Get all tags and filter for major versions (vX format)
      latest_version=$(gh api "repos/$action/tags" --jq '.[].name | select(test("^v[0-9]+$"))' | head -n1 2>/dev/null || echo "")

      if [[ -n $latest_version && $latest_version != "$current_version" ]]; then
        echo "Updating $action from $current_version to $latest_version in $workflow"
        sed -i "s|uses: $action@$current_version|uses: $action@$latest_version|g" "$workflow"
      fi
    done
  fi
done
