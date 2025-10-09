#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

sops \
  --encrypt \
  "$(dirname "$0")"/jellyfin/.env > \
  "$(dirname "$0")"/jellyfin/.enc.env

sops \
  --encrypt \
  "$(dirname "$0")"/metatube/.env > \
  "$(dirname "$0")"/metatube/.enc.env
