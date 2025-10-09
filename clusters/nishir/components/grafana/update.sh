#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

sops \
  --encrypt \
  "$(dirname "$0")"/grafana-cloud-logs/.env > \
  "$(dirname "$0")"/grafana-cloud-logs/.enc.env

sops \
  --encrypt \
  "$(dirname "$0")"/grafana-cloud-metrics/.env > \
  "$(dirname "$0")"/grafana-cloud-metrics/.enc.env

sops \
  --encrypt \
  "$(dirname "$0")"/grafana-cloud-otlp/.env > \
  "$(dirname "$0")"/grafana-cloud-otlp/.enc.env
