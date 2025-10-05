#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

sops \
  --decrypt \
  "$(dirname "$0")"/sonarr/.enc.env > \
  "$(dirname "$0")"/sonarr/.env
