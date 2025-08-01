#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Fetch longhorn_backupstore output from terraform
LONGHORN_CONFIG=$(tofu -chdir="$(dirname "$0")"/../../../../infra/nishir-services output -json longhorn_backupstore)

# Extract AWS credentials and bucket info
AWS_ACCESS_KEY_ID=$(echo "$LONGHORN_CONFIG" | jq -r '.access_key_id')
AWS_SECRET_ACCESS_KEY=$(echo "$LONGHORN_CONFIG" | jq -r '.secret_access_key')
AWS_ENDPOINTS=$(echo "$LONGHORN_CONFIG" | jq -r '.endpoint')
BUCKET=$(echo "$LONGHORN_CONFIG" | jq -r '.bucket')
REGION=$(echo "$LONGHORN_CONFIG" | jq -r '.region')

# Update the decrypted content
yq -i \
  ".secretGenerator[0].literals[0] = \"AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID\"" \
  "$(dirname "$0")"/kustomization.yaml
yq -i \
  ".secretGenerator[0].literals[1] = \"AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY\"" \
  "$(dirname "$0")"/kustomization.yaml
yq -i \
  ".secretGenerator[0].literals[2] = \"AWS_ENDPOINTS=$AWS_ENDPOINTS\"" \
  "$(dirname "$0")"/kustomization.yaml

# Add backup target annotation
yq -i \
  ".secretGenerator[0].options.annotations.[\"longhorn.io/backup-target\"] = \"s3://${BUCKET}@${REGION}/\"" \
  "$(dirname "$0")"/kustomization.yaml

# Re-encrypt with SOPS
sops encrypt --encrypted-regex "^(literals)$" "$(dirname "$0")"/kustomization.yaml >"$(dirname "$0")"/kustomization.enc.yaml
