#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

# jellyfin: update image and set version label
go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "docker.io/jellyfin/jellyfin" \
  --name "jellyfin" \
  --dir "$(dirname "$0")" \
  --label-key "app.kubernetes.io/version" \
  --tag-regex '(?i)^v?(?P<version>\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?)$'

# metatube: update image (no label)
go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "ghcr.io/metatube-community/metatube-server" \
  --name "metatube" \
  --dir "$(dirname "$0")" \
  --tag-regex '(?i)^v?(?P<version>\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?)$'
