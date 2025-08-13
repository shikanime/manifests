#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

sops \
  --encrypt \
  --encrypted-regex "^(registration_shared_secret|form_secret|macaroon_secret_key)$" \
  "$(dirname "$0")"/homeserver.yaml > \
  "$(dirname "$0")"/homeserver.enc.yaml
