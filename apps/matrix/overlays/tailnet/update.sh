#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

for dir in "$(dirname "$0")"/*; do
  if [ -f "$dir/update.sh" ]; then
    bash "$dir/update.sh" 2>&1 |
      sed 's/^/['"$(basename "$dir")"'] /' &
  fi
done
