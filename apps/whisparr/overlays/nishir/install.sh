#!/usr/bin/env nix
#! nix develop --impure --command bash
# shellcheck shell=bash

set -o errexit
set -o nounset
set -o pipefail

sops \
  --decrypt \
  "$(dirname "$0")"/whisparr/.enc.env > \
  "$(dirname "$0")"/whisparr/.env
