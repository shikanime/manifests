#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

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
GIT_HASH=$(nix hash to-sri --type sha256 ${GIT_PREFETCH})

sed -i \
  -e "s|version = \".*\"|version = \"${LATEST_VERSION:-}\"|" \
  -e "s|hash = \".*\"|hash = \"${GIT_HASH}\"|" \
  "$(dirname "$0")"/default.nix
