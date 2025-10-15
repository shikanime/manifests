#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

# Define container images to check
declare -A IMAGES=(
  ["caddy"]="docker.io/library/caddy"
  ["kratos"]="docker.io/oryd/kratos"
  ["kratos-postgres"]="docker.io/library/postgres"
  ["kratos-selfservice-ui-node"]="docker.io/oryd/kratos-selfservice-ui-node"
)

for IMAGE_NAME in "${!IMAGES[@]}"; do
  FULL_IMAGE="${IMAGES[$IMAGE_NAME]}"
  if [[ $IMAGE_NAME == "kratos-postgres" ]]; then
    LATEST_VERSION=$(
      skopeo list-tags "docker://${FULL_IMAGE}" |
        jq -r '.Tags | map(select(test("^[0-9]+(\\.[0-9]+)?(\\.[0-9]+)?$"))) | sort_by(. | split("[.-]") | map(tonumber? // 0)) | last'
    )
  else
    LATEST_VERSION=$(
      skopeo list-tags "docker://${FULL_IMAGE}" |
        jq -r '.Tags | map(select(test("^v?[0-9]+[.-].*[0-9]+\\.[0-9]+$"))) | sort_by(. | split("[.-]") | map(tonumber? // 0)) | last'
    )
  fi
  if [[ -z $LATEST_VERSION ]]; then
    echo "Image '$FULL_IMAGE' not found in registry."
  else
    (cd "$(dirname "$0")" &&
      kustomize edit set image "${IMAGE_NAME}=${FULL_IMAGE}:${LATEST_VERSION}")
    if [[ $IMAGE_NAME == "synapse" ]]; then
      yq -i \
        ".labels.[].pairs.[\"app.kubernetes.io/version\"] = \"${LATEST_VERSION#v}\"" \
        "$(dirname "$0")"/kustomization.yaml
    fi
  fi
done
