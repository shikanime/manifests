#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Define an array of charts to check
declare -A MANIFESTS=(
  ["tailscale"]="tailscale/tailscale-operator"
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
  local MANIFEST_NAME=$1
  echo "[${MANIFEST_NAME}] Checking for updates for ${MANIFESTS[$MANIFEST_NAME]}..."

  IFS=' ' read -r -a CHARTS <<<"${MANIFESTS[$MANIFEST_NAME]}"

  for INDEX in "${!CHARTS[@]}"; do
    CHART_NAME="${CHARTS[$INDEX]}"

    LATEST_VERSION=$(
      helm search repo "$CHART_NAME" --output json |
        jq -r 'map(select(.name == "'"$CHART_NAME"'") | .version | select(test("^[v]?[0-9]+\\.[0-9]+\\.[0-9]+$"))) | last // empty'
    )
    echo "[${MANIFEST_NAME}] Latest version of $CHART_NAME: $LATEST_VERSION"

    if [[ -z $LATEST_VERSION ]]; then
      echo "[${MANIFEST_NAME}] Chart '$CHART_NAME' not found in repository."
    else
      echo "[${MANIFEST_NAME}] Found latest version: $LATEST_VERSION"

      TEMPLATE_FILE="$(dirname "$0")/templates/manifests/${MANIFEST_NAME}.yaml"
      if [[ -f $TEMPLATE_FILE ]]; then
        echo "[${MANIFEST_NAME}] Updating $TEMPLATE_FILE..."
        REPO_URL="${REPOS[${CHART_NAME%%/*}]}"
        OCCURRENCE=$((INDEX + 1))

        REPO_LINE=$(grep -n "repo:" "$TEMPLATE_FILE" | cut -d: -f1 | sed -n "${OCCURRENCE}p")
        CHART_LINE=$(grep -n "chart:" "$TEMPLATE_FILE" | cut -d: -f1 | sed -n "${OCCURRENCE}p")
        VERSION_LINE=$(grep -n "version:" "$TEMPLATE_FILE" | cut -d: -f1 | sed -n "${OCCURRENCE}p")

        sed -i \
          -e "${REPO_LINE}s|repo: .*$|repo: ${REPO_URL}|" \
          -e "${CHART_LINE}s|chart: .*$|chart: ${CHART_NAME#*/}|" \
          -e "${VERSION_LINE}s|version: .*$|version: ${LATEST_VERSION}|" \
          "$TEMPLATE_FILE"
        echo "[${MANIFEST_NAME}] Updated $TEMPLATE_FILE"
      else
        echo "[${MANIFEST_NAME}] Template file not found: $TEMPLATE_FILE"
      fi
    fi
  done
}

# Process manifests in parallel
for MANIFEST_NAME in "${!MANIFESTS[@]}"; do
  update "$MANIFEST_NAME" &
done

wait
