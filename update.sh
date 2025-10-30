#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

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
  -e "s|version = \".*\"|version = \"${LATEST_VERSION:-}\"|g" \
  -e "s|hash = \".*\"|hash = \"${GIT_HASH}\"|g" \
  "$(dirname "$0")/flake.nix"

wait
