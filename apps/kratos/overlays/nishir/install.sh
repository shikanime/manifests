#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

sops \
  --decrypt \
  "$(dirname "$0")"/kratos/.enc.env > \
  "$(dirname "$0")"/kratos/.env

sops \
  --decrypt \
  "$(dirname "$0")"/kratos-postgres/kratos.enc.yaml > \
  "$(dirname "$0")"/kratos-postgres/kratos.yaml
