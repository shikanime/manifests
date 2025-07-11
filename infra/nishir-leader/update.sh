#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Define an array of charts to check
declare -A TEMPLATES=(
  ["tailscale-operator"]="tailscale/tailscale-operator"
)

declare -A REPOS=(
  ["tailscale"]="https://pkgs.tailscale.com/helmcharts"
)

# Add each repository to helm using the repo name and URL from REPOS array
for REPO_NAME in "${!REPOS[@]}"; do
  REPO_URL="${REPOS[$REPO_NAME]}"
  helm repo add "$REPO_NAME" "$REPO_URL" &>/dev/null &
done

wait

# Update the repository information
helm repo update

update() {
  local TEMPLATE_NAME=$1
  echo "[${TEMPLATE_NAME}] Checking for updates for ${TEMPLATES[$TEMPLATE_NAME]}..."

  IFS=' ' read -r -a CHARTS <<<"${TEMPLATES[$TEMPLATE_NAME]}"

  for INDEX in "${!CHARTS[@]}"; do
    CHART_NAME="${CHARTS[$INDEX]}"

    LATEST_VERSION=$(
      helm search repo "$CHART_NAME" --output json |
        jq -r 'map(select(.name == "'"$CHART_NAME"'") | .version | select(test("^[v]?[0-9]+\\.[0-9]+\\.[0-9]+$"))) | last // empty'
    )
    echo "[${TEMPLATE_NAME}] Latest version of $CHART_NAME: $LATEST_VERSION"

    if [[ -z $LATEST_VERSION ]]; then
      echo "[${TEMPLATE_NAME}] Chart '$CHART_NAME' not found in repository."
    else
      echo "[${TEMPLATE_NAME}] Found latest version: $LATEST_VERSION"

      TEMPLATE_FILE="$(dirname "$0")/templates/manifests/${TEMPLATE_NAME}.yaml.tftpl"
      if [[ -f $TEMPLATE_FILE ]]; then
        echo "[${TEMPLATE_NAME}] Updating $TEMPLATE_FILE..."
        REPO_URL="${REPOS[${CHART_NAME%%/*}]}"
        yq -i "(select(.apiVersion == \"helm.cattle.io/v1\" and .kind == \"HelmChart\" and .metadata.name == \"$TEMPLATE_NAME\") | .spec.chart = \"${CHART_NAME#*/}\" | .spec.repo = \"$REPO_URL\" | .spec.version = \"$LATEST_VERSION\") // ." "$TEMPLATE_FILE"
        echo "[${TEMPLATE_NAME}] Updated $TEMPLATE_FILE"
      else
        echo "[${TEMPLATE_NAME}] Template file not found: $TEMPLATE_FILE"
      fi
    fi
  done
}

# Process manifests in parallel
for TEMPLATE_NAME in "${!TEMPLATES[@]}"; do
  update "$TEMPLATE_NAME" &
done

wait
