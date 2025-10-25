#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

sops \
  --encrypt \
  --encrypted-regex "^(avatar_proxy_key|as_token|hs_token|pickle_key|server_key|shared_secret|signing_key)$" \
  "$(dirname "$0")"/config.yaml > \
  "$(dirname "$0")"/config.enc.yaml

sops \
  --encrypt \
  --encrypted-regex "^(as_token|hs_token)$" \
  "$(dirname "$0")"/registration.yaml > \
  "$(dirname "$0")"/registration.enc.yaml
