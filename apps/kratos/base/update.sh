#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "docker.io/library/caddy" \
  --name "caddy" \
  --dir "$(dirname "$0")" \
  --tag-regex '(?i)^v?(?P<version>\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?)$'

// kratos: v-prefixed and may contain prerelease/build; extract embedded semver
go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "docker.io/oryd/kratos" \
  --name "kratos" \
  --dir "$(dirname "$0")" \
  --label-key "app.kubernetes.io/version" \
  --tag-regex '(?i).*?(?P<version>\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?)'

// postgres: allow 15, 15.6, 15.6.1 (no label)
go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "docker.io/library/postgres" \
  --name "kratos-postgres" \
  --dir "$(dirname "$0")" \
  --tag-regex '(?i)^v?(?P<version>\d+(?:\.\d+){0,2})$'

// ui: extract embedded semver (no label)
go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "docker.io/oryd/kratos-selfservice-ui-node" \
  --name "kratos-selfservice-ui-node" \
  --dir "$(dirname "$0")" \
  --tag-regex '(?i).*?(?P<version>\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?)'
