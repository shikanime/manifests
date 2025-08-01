#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Get current password if it exists
CURRENT_PASSWORD=$(yq '.secretGenerator[0].literals[0]' "$(dirname "$0")"/kustomization.yaml | sed 's/^password=//')

# Generate new password only if current password is empty
if [ -z "$CURRENT_PASSWORD" ]; then
  PASSWORD=$(openssl rand -base64 32)
else
  PASSWORD="$CURRENT_PASSWORD"
fi

# Handle SOPS encryption/decryption
yq -i \
  ".secretGenerator[0].literals[0] = \"password=$PASSWORD\"" \
  "$(dirname "$0")"/kustomization.yaml

sops \
  --encrypt \
  --encrypted-regex "^(literals)$" \
  "$(dirname "$0")"/kustomization.yaml > \
  "$(dirname "$0")/kustomization.enc.yaml"
