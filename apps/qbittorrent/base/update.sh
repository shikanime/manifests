#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

go run "$(dirname "$0")"/../../../cmd/automata update kustomization \
  --image "lscr.io/linuxserver/qbittorrent" \
  --name "qbittorrent" \
  --dir "$(dirname "$0")" \
  --label-key "app.kubernetes.io/version" \
  --tag-regex '^\d+\.\d+\.\d+$' \
  --exclude-tags '20.04.1,14.3.9'
