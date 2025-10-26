#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "docker.io/library/caddy" \
  --name "caddy" \
  --dir "$(dirname "$0")" \
  --tag-regex '^\d+\.\d+\.\d+$'

# kratos: v-prefixed and pre-release (main app label kept)
go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "docker.io/oryd/kratos" \
  --name "kratos" \
  --dir "$(dirname "$0")" \
  --label-key "app.kubernetes.io/version" \
  --tag-regex '^v?[0-9]+[.\-].*[0-9]+\.[0-9]+$'

# postgres: allow 15, 15.6, 15.6.1 (no label)
go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "docker.io/library/postgres" \
  --name "kratos-postgres" \
  --dir "$(dirname "$0")" \
  --tag-regex '^\d+(\.\d+)?(\.\d+)?$'

# ui: allow v-prefixed and pre-release (no label)
go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "docker.io/oryd/kratos-selfservice-ui-node" \
  --name "kratos-selfservice-ui-node" \
  --dir "$(dirname "$0")" \
  --tag-regex '^v?[0-9]+[.\-].*[0-9]+\.[0-9]+$'
