#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Fetch tailscale_operator output from terraform
TAILSCALE_CONFIG=$(tofu -chdir="$(dirname "$0")"/../../../../infra/nishir-services output -json tailscale_operator)

# Extract client_id and client_secret
CLIENT_ID=$(echo "$TAILSCALE_CONFIG" | jq -r '.client_id')
CLIENT_SECRET=$(echo "$TAILSCALE_CONFIG" | jq -r '.client_secret')

# Update the decrypted content
yq -i \
  ".secretGenerator[0].literals[0] = \"client_id=$CLIENT_ID\"" \
  "$(dirname "$0")"/kustomization.yaml
yq -i \
  ".secretGenerator[0].literals[1] = \"client_secret=$CLIENT_SECRET\"" \
  "$(dirname "$0")"/kustomization.yaml

# Re-encrypt with SOPS
sops encrypt --encrypted-regex "^(literals)$" "$(dirname "$0")"/kustomization.yaml > "$(dirname "$0")"/kustomization.enc.yaml
