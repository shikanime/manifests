#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Get current admin-token if it exists
CURRENT_ADMIN_TOKEN=$(yq '.secretGenerator[0].literals[0]' "$(dirname "$0")"/kustomization.yaml | sed 's/^admin-token=//')

# Generate new admin-token only if current admin-token is empty
if [ -z "$CURRENT_ADMIN_TOKEN" ]; then
  # Generate a random token that looks like an Argon2id hash
  SALT=$(openssl rand -base64 24)
  HASH=$(openssl rand -base64 43)
  ADMIN_TOKEN="\$argon2id\$v=19\$m=65540,t=3,p=4\$${SALT}\$${HASH}"
else
  ADMIN_TOKEN="$CURRENT_ADMIN_TOKEN"
fi

# Handle SOPS encryption/decryption
yq -i \
  ".secretGenerator[0].literals[0] = \"admin-token=$ADMIN_TOKEN\"" \
  "$(dirname "$0")"/kustomization.yaml

sops \
  --encrypt \
  --encrypted-regex "^(literals)$" \
  "$(dirname "$0")"/kustomization.yaml > \
  "$(dirname "$0")"/kustomization.enc.yaml
