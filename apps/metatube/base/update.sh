#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Define container images to check
declare -A IMAGES=(
  ["metatube"]="ghcr.io/metatube-community/metatube-server"
)

for IMAGE_NAME in "${!IMAGES[@]}"; do
  FULL_IMAGE="${IMAGES[$IMAGE_NAME]}"
  LATEST_VERSION=$(
    skopeo list-tags "docker://${FULL_IMAGE}" |
      jq -r '.Tags | map(select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))) | sort_by(split(".") | map(tonumber)) | last'
  )
  if [[ -z $LATEST_VERSION ]]; then
    echo "Image '$FULL_IMAGE' not found in registry."
  else
    (cd "$(dirname "$0")" &&
      kustomize edit set image "${IMAGE_NAME}=${FULL_IMAGE}:${LATEST_VERSION}")
    yq -i \
      ".labels.[].pairs.[\"app.kubernetes.io/version\"] = \"${LATEST_VERSION}\"" \
      "$(dirname "$0")"/kustomization.yaml
  fi
done

# Get current token if it exists
CURRENT_TOKEN=$(yq '.secretGenerator[0].literals[0]' "$(dirname "$0")"/kustomization.yaml | sed 's/^token=//')

# Generate new token only if current token is empty
if [ -z "$CURRENT_TOKEN" ]; then
  TOKEN=$(openssl rand -base64 32)
else
  TOKEN="$CURRENT_TOKEN"
fi

# Handle SOPS encryption/decryption
yq -i \
  ".secretGenerator[0].literals[0] = \"token=$TOKEN\"" \
  "$(dirname "$0")"/kustomization.yaml

sops \
  --encrypt \
  --encrypted-regex "^(literals)$" \
  "$(dirname "$0")"/kustomization.yaml > \
  "$(dirname "$0")"/kustomization.enc.yaml
