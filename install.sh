#!/usr/bin/env nix
#! nix develop --impure --command bash
# shellcheck shell=bash

set -o errexit
set -o nounset
set -o pipefail

for app_dir in "$(dirname "$0")"/apps/* "$(dirname "$0")"/clusters/*; do
  # Update base directory
  base_dir="$app_dir/base"
  if [ -f "$base_dir/install.sh" ]; then
    bash "$base_dir/install.sh" 2>&1 |
      sed 's/^/['"$(basename "$app_dir")"'] /' &
  fi

  # Update component directories
  for component_dir in "$app_dir"/components/*; do
    if [ -f "$component_dir/install.sh" ]; then
      bash "$component_dir/install.sh" 2>&1 |
        sed 's/^/['"$(basename "$app_dir")"'\/'"$(basename "$component_dir")"'] /' &
    fi
  done

  # Update overlay directories
  for overlay_dir in "$app_dir"/overlays/*; do
    if [ -f "$overlay_dir/install.sh" ]; then
      bash "$overlay_dir/install.sh" 2>&1 |
        sed 's/^/['"$(basename "$app_dir")"'\/'"$(basename "$overlay_dir")"'] /' &
    fi
  done
done

for dir in "$(dirname "$0")"/infra/*; do
  if [ -f "$dir/install.sh" ]; then
    bash "$dir/install.sh" 2>&1 |
      sed "s/^/[$(basename "$dir")] /" &
  fi
done

wait
