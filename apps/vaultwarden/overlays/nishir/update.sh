#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

sops \
  --encrypt \
  "$(dirname "$0")"/vaultwarden/.env > \
  "$(dirname "$0")"/vaultwarden/.enc.env
