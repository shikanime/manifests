#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

sops \
  --encrypt \
  "$(dirname "$0")"/kratos/.env > \
  "$(dirname "$0")"/kratos/.enc.env

sops \
  --encrypt \
  "$(dirname "$0")"/kratos-postgres/.env > \
  "$(dirname "$0")"/kratos-postgres/.enc.env
