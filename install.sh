#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

for dir in "$(dirname "$0")"/infra/*; do
  if [ -f "$dir/install.sh" ]; then
    bash "$dir/install.sh" 2>&1 |
      sed "s/^/[$(basename "$dir")] /" &
  fi
done

wait
