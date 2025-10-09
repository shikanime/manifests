#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

sops \
  --decrypt \
  "$(dirname "$0")"/grafana-cloud-logs/.enc.env > \
  "$(dirname "$0")"/grafana-cloud-logs/.env

sops \
  --decrypt \
  "$(dirname "$0")"/grafana-cloud-metrics/.enc.env > \
  "$(dirname "$0")"/grafana-cloud-metrics/.env

sops \
  --decrypt \
  "$(dirname "$0")"/grafana-cloud-otlp/.enc.env > \
  "$(dirname "$0")"/grafana-cloud-otlp/.env
