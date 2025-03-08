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
