#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "ghcr.io/hotio/whisparr" \
  --name "whisparr" \
  --dir "$(dirname "$0")" \
  --label-key "app.kubernetes.io/version" \
  --tag-regex '^v[0-9]+[.\-].*[0-9]+\.[0-9]+$' \
  --label-trim-prefix 'v3-'
