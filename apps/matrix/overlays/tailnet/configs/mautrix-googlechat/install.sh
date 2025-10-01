#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

sops --decrypt "$(dirname "$0")"/config.enc.yaml >"$(dirname "$0")"/config.yaml
