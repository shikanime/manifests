#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Update gitignore
# gitnr create \
#   ghc:Nix \
#   repo:shikanime/gitignore/refs/heads/main/Devenv.gitignore \
#   tt:jetbrains+all \
#   tt:linux \
#   tt:macos \
#   tt:terraform \
#   tt:vim \
#   tt:visualstudiocode \
#   tt:windows >.gitignore

for app_dir in "$(dirname "$0")"/apps/* "$(dirname "$0")"/clusters/*; do
  # Update base directory
  base_dir="$app_dir/base"
  if [ -f "$base_dir/update.sh" ]; then
    bash "$base_dir/update.sh" 2>&1 |
      sed 's/^/['"$(basename "$app_dir")"'] /' &
  fi

  # Update component directories
  for component_dir in "$app_dir"/components/*; do
    if [ -f "$component_dir/update.sh" ]; then
      bash "$component_dir/update.sh" 2>&1 |
        sed 's/^/['"$(basename "$app_dir")"'\/'"$(basename "$component_dir")"'] /' &
    fi
  done

  # Update overlay directories
  for overlay_dir in "$app_dir"/overlays/*; do
    if [ -f "$overlay_dir/update.sh" ]; then
      bash "$overlay_dir/update.sh" 2>&1 |
        sed 's/^/['"$(basename "$app_dir")"'\/'"$(basename "$overlay_dir")"'] /' &
    fi
  done
done

for dir in "$(dirname "$0")"/infra/*; do
  if [ -f "$dir/update.sh" ]; then
    bash "$dir/update.sh" 2>&1 |
      sed 's/^/['"$(basename "$dir")"'] /' &
  fi
done

for dir in "$(dirname "$0")"/bootstraps/*; do
  if [ -f "$dir/update.sh" ]; then
    bash "$dir/update.sh" 2>&1 |
      sed 's/^/['"$(basename "$dir")"'] /' &
  fi
done

# Update Longhorn package
LATEST_VERSION=$(
  curl --silent \
    https://api.github.com/repos/longhorn/cli/releases/latest |
    jq -r '.tag_name | ltrimstr("v")'
)

COMMIT=$(
  curl --silent \
    https://api.github.com/repos/longhorn/cli/tags |
    jq -r "map(select(.name == \"v${LATEST_VERSION}\")) | .[0] | .commit.sha"
)

GIT_PREFETCH=$(nix-prefetch-url --unpack https://github.com/longhorn/cli/archive/${COMMIT}.tar.gz)
GIT_HASH=$(nix hash convert --hash-algo sha256 --to sri ${GIT_PREFETCH})

sed -i \
  -e "s|version = \".*\"|version = \"${LATEST_VERSION:-}\"|" \
  -e "s|hash = \".*\"|hash = \"${GIT_HASH}\"|" \
  "$(dirname "$0")/flake.nix"

wait
