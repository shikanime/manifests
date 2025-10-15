#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

# Fetch tailscale_operator output from terraform
TAILSCALE_CONFIG=$(tofu -chdir="$(dirname "$0")"/../../../../infra/nishir-services output -json tailscale_operator)

# Extract client_id and client_secret
CLIENT_ID=$(echo "$TAILSCALE_CONFIG" | jq -r '.client_id')
CLIENT_SECRET=$(echo "$TAILSCALE_CONFIG" | jq -r '.client_secret')

# Update the decrypted content
sed -i \
  -e "s|client_id=.*|client_id=$CLIENT_ID|g" \
  -e "s|client_secret=.*|client_secret=$CLIENT_SECRET|g" \
  "$(dirname "$0")"/oauth-client/.env

# Re-encrypt with SOPS
sops \
  --encrypt \
  "$(dirname "$0")"/oauth-client/.env > \
  "$(dirname "$0")"/oauth-client/.enc.env
