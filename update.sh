#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

for dir in "$(dirname "$0")"/apps/*/base; do
  if [ -f "$dir/update.sh" ]; then
    bash "$dir/update.sh" 2>&1 |
      sed "s/^/[$(basename "$(dirname "$dir")")] /" &
  fi
done

for dir in "$(dirname "$0")"/nix/pkgs/*; do
  if [ -f "$dir/update.sh" ]; then
    bash "$dir/update.sh" 2>&1 |
      sed "s/^/[$(basename "$(dirname "$dir")")] /" &
  fi
done

for dir in "$(dirname "$0")"/infra/*; do
  if [ -f "$dir/update.sh" ]; then
    bash "$dir/update.sh" 2>&1 |
      sed "s/^/[$(basename "$dir")] /" &
  fi
done

wait
