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
GIT_HASH=$(nix hash convert --hash-algo sha256 --to sri ${GIT_PREFETCH})

sed -i \
  -e "s|version = \".*\"|version = \"${LATEST_VERSION:-}\"|" \
  -e "s|hash = \".*\"|hash = \"${GIT_HASH}\"|" \
  "$(dirname "$0")"/default.nix

# Only update build date if default.nix was modified
if [ -n "$(git diff "$(dirname "$0")/default.nix")" ]; then
  BUILD_DATE=$(date --iso-8601=seconds)

  sed -i \
    -e "s|\"-X github.com/longhorn/cli/meta.BuildDate=.*\"|\"-X github.com/longhorn/cli/meta.BuildDate=${BUILD_DATE}\"|" \
    "$(dirname "$0")"/default.nix
fi
