#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

sops \
  --encrypt \
  --encrypted-regex "^(as_token|hs_token|shared_secret)$" \
  "$(dirname "$0")"/config.yaml > \
  "$(dirname "$0")"/config.enc.yaml

sops \
  --encrypt \
  --encrypted-regex "^(as_token|hs_token)$" \
  "$(dirname "$0")"/registration.yaml > \
  "$(dirname "$0")"/registration.enc.yaml
