#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Update gitignore
gitnr create \
  ghc:Nix \
  repo:shikanime/gitignore/refs/heads/main/Devenv.gitignore \
  tt:jetbrains+all \
  tt:linux \
  tt:macos \
  tt:terraform \
  tt:vim \
  tt:visualstudiocode \
  tt:windows >.gitignore

for app_dir in "$(dirname "$0")"/apps/* "$(dirname "$0")"/clusters/*; do
  # Update base directory
  base_dir="$app_dir/base"
  if [ -f "$base_dir/update.sh" ]; then
    bash "$base_dir/update.sh" 2>&1 |
      sed 's/^/['"$(basename "$app_dir")"'] /' &
  fi

  # Update overlay directories
  for overlay_dir in "$app_dir"/overlays/*; do
    if [ -f "$overlay_dir/update.sh" ]; then
      bash "$overlay_dir/update.sh" 2>&1 |
        sed 's/^/['"$(basename "$app_dir")"'\/'"$(basename "$overlay_dir")"'] /' &
    fi
  done
done

for dir in "$(dirname "$0")"/nix/pkgs/*; do
  if [ -f "$dir/update.sh" ]; then
    bash "$dir/update.sh" 2>&1 |
      sed 's/^/['"$(basename "$(dirname "$dir")")"'] /' &
  fi
done

for dir in "$(dirname "$0")"/infra/*; do
  if [ -f "$dir/update.sh" ]; then
    bash "$dir/update.sh" 2>&1 |
      sed 's/^/['"$(basename "$dir")"'] /' &
  fi
done

wait
