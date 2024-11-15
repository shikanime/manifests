#!/bin/bash

# Define container images to check
declare -A IMAGES=(
  ["jackett"]="lscr.io/linuxserver/jackett"
)

for IMAGE_NAME in "${!IMAGES[@]}"; do
  FULL_IMAGE="${IMAGES[$IMAGE_NAME]}"
  LATEST_VERSION=$(
    skopeo list-tags docker://${FULL_IMAGE} |
      jq -r '.Tags | map(select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))) | sort_by(split(".") | map(tonumber)) | last'
  )
  if [[ -z $LATEST_VERSION ]]; then
    echo "Image '$FULL_IMAGE' not found in registry."
  else
    (cd "$(dirname "$0")" &&
      kustomize edit set image ${IMAGE_NAME}=${FULL_IMAGE}:${LATEST_VERSION} &&
      kustomize edit set label app.kubernetes.io/version:${LATEST_VERSION})
  fi
done
