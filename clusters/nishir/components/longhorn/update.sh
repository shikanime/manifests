#!/usr/bin/env nix
#! nix develop --impure --command bash

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

# Add backup target annotation
yq -i \
  ".secretGenerator[0].options.annotations.[\"longhorn.io/backup-target\"] = \"s3://${BUCKET}@${REGION}/\"" \
  "$(dirname "$0")"/kustomization.yaml

# Update the environment file
sed -i \
  -e "s|AWS_ACCESS_KEY_ID=.*|AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID|g" \
  -e "s|AWS_SECRET_ACCESS_KEY=.*|AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY|g" \
  -e "s|AWS_ENDPOINTS=.*|AWS_ENDPOINTS=$AWS_ENDPOINTS|g" \
  "$(dirname "$0")"/configs/longhorn-hetzner-backups.env

# Re-encrypt with SOPS
sops \
  --encrypt \
  "$(dirname "$0")"/longhorn-hetzner-backups/.env > \
  "$(dirname "$0")"/longhorn-hetzner-backups/.enc.env
