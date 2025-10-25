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

go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "docker.io/library/busybox" \
  --name "busybox" \
  --dir "$(dirname "$0")" \
  --tag-regex '^\d+\.\d+\.\d+$'

go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "dock.mau.dev/mautrix/discord" \
  --name "mautrix-discord" \
  --dir "$(dirname "$0")" \
  --tag-regex '^v?\d+\.\d+\.\d+$'

go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "dock.mau.dev/mautrix/googlechat" \
  --name "mautrix-googlechat" \
  --dir "$(dirname "$0")" \
  --tag-regex '^v?\d+\.\d+\.\d+$'

go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "dock.mau.dev/mautrix/meta" \
  --name "mautrix-meta" \
  --dir "$(dirname "$0")" \
  --tag-regex '^v?\d+\.\d+\.\d+$'

go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "dock.mau.dev/mautrix/signal" \
  --name "mautrix-signal" \
  --dir "$(dirname "$0")" \
  --tag-regex '^v?\d+\.\d+\.\d+$'

go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "dock.mau.dev/mautrix/slack" \
  --name "mautrix-slack" \
  --dir "$(dirname "$0")" \
  --tag-regex '^v?\d+\.\d+\.\d+$'

go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "dock.mau.dev/mautrix/whatsapp" \
  --name "mautrix-whatsapp" \
  --dir "$(dirname "$0")" \
  --tag-regex '^v?\d+\.\d+\.\d+$'

go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "docker.io/matrixdotorg/synapse" \
  --name "synapse" \
  --dir "$(dirname "$0")" \
  --label-key "app.kubernetes.io/version" \
  --tag-regex '^v?\d+\.\d+\.\d+$' \
  --label-trim-prefix 'v'
