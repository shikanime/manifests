#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Get current password if it exists
CURRENT_PASSWORD=$(yq '.secretGenerator[] | select(.name == "rclone-ftp") | .literals[1]' "$(dirname "$0")"/kustomization.yaml | sed 's/^password=//' 2>/dev/null || echo "")

# Generate new password only if current password is empty
if [ -z "$CURRENT_PASSWORD" ]; then
  PASSWORD=$(openssl rand -base64 32)
else
  PASSWORD="$CURRENT_PASSWORD"
fi

# Generate bcrypt hash for htpasswd (using cost 10)
BCRYPT_HASH=$(htpasswd -bnBC 10 "" "$PASSWORD" | tr -d ':')

# Update both secrets in the kustomization file
yq -i \
  ".secretGenerator[0].literals[1] = \"password=$PASSWORD\"" \
  "$(dirname "$0")"/kustomization.yaml
yq -i \
  ".secretGenerator[1].literals[0] = \"htpasswd=rclone:$BCRYPT_HASH\"" \
  "$(dirname "$0")"/kustomization.yaml

sops \
  --encrypt \
  --encrypted-regex "^(literals)$" \
  "$(dirname "$0")"/kustomization.yaml > \
  "$(dirname "$0")/kustomization.enc.yaml"
