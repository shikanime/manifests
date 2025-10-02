#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

# Define container images to check
declare -A IMAGES=(
  ["caddy"]="docker.io/library/caddy"
  ["busybox"]="docker.io/library/busybox"
  ["mautrix-googlechat"]="dock.mau.dev/mautrix/googlechat"
  ["mautrix-slack"]="dock.mau.dev/mautrix/slack"
  ["synapse"]="docker.io/matrixdotorg/synapse"
)

for IMAGE_NAME in "${!IMAGES[@]}"; do
  FULL_IMAGE="${IMAGES[$IMAGE_NAME]}"
  LATEST_VERSION=$(
    skopeo list-tags "docker://${FULL_IMAGE}" |
      jq -r '.Tags | map(select(test("^v?[0-9]+\\.[0-9]+\\.[0-9]+$"))) | sort_by(. | split("[.-]") | map(tonumber? // 0)) | last'
  )
  if [[ -z $LATEST_VERSION ]]; then
    echo "Image '$FULL_IMAGE' not found in registry."
  else
    (cd "$(dirname "$0")" &&
      kustomize edit set image "${IMAGE_NAME}=${FULL_IMAGE}:${LATEST_VERSION}")
    yq -i \
      ".labels.[].pairs.[\"app.kubernetes.io/version\"] = \"${LATEST_VERSION#v}\"" \
      "$(dirname "$0")"/kustomization.yaml
  fi
done
