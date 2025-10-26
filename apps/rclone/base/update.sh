#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "docker.io/rclone/rclone" \
  --name "rclone" \
  --dir "$(dirname "$0")" \
  --label-key "app.kubernetes.io/version" \
  --tag-regex '^\d+\.\d+\.\d+$'
