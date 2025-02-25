#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Define an array of charts to check
declare -A MANIFESTS=(
  ["cert-manager"]="jetstack/cert-manager"
  ["grafana-monitoring"]="grafana/k8s-monitoring"
  ["fleet"]="fleet/fleet-crd fleet/fleet"
  ["longhorn"]="longhorn/longhorn"
  ["nfd"]="node-feature-discovery/node-feature-discovery"
  ["tailscale"]="tailscale/tailscale-operator"
  ["vpa"]="fairwinds/vpa"
)

declare -A REPOS=(
  ["fairwinds"]="https://charts.fairwinds.com/stable"
  ["grafana"]="https://grafana.github.io/helm-charts"
  ["fleet"]="https://rancher.github.io/fleet-helm-charts"
  ["jetstack"]="https://charts.jetstack.io"
  ["longhorn"]="https://charts.longhorn.io"
  ["node-feature-discovery"]="https://kubernetes-sigs.github.io/node-feature-discovery/charts"
  ["tailscale"]="https://pkgs.tailscale.com/helmcharts"
)

# Add each repository to helm using the repo name and URL from REPOS array
for REPO_NAME in "${!REPOS[@]}"; do
  REPO_URL="${REPOS[$REPO_NAME]}"
  helm repo add "$REPO_NAME" "$REPO_URL" &>/dev/null
done

# Update the repository information (optional, but recommended for latest info)
helm repo update

for MANIFEST_NAME in "${!MANIFESTS[@]}"; do
  echo "Checking for updates for ${MANIFESTS[$MANIFEST_NAME]}..."

  # Split the chart string into an array
  IFS=' ' read -r -a CHARTS <<<"${MANIFESTS[$MANIFEST_NAME]}"

  for INDEX in "${!CHARTS[@]}"; do
    CHART_NAME="${CHARTS[$INDEX]}"

    # Search for the latest version of the chart
    LATEST_VERSION=$(
      helm search repo "$CHART_NAME" --output json |
        jq -r 'map(select(.name == "'"$CHART_NAME"'") | .version | select(test("^[v]?[0-9]+\\.[0-9]+\\.[0-9]+$"))) | last // empty'
    )
    echo "Latest version of $CHART_NAME: $LATEST_VERSION"

    # Check if the chart was found
    if [[ -z $LATEST_VERSION ]]; then
      echo "Chart '$CHART_NAME' not found in repository."
    else
      echo "Found latest version: $LATEST_VERSION"

      TEMPLATE_FILE="$(dirname "$0")/templates/manifests/${MANIFEST_NAME}.yaml.tftpl"
      if [[ -f $TEMPLATE_FILE ]]; then
        echo "Updating $TEMPLATE_FILE..."
        REPO_URL="${REPOS[${CHART_NAME%%/*}]}"
        OCCURRENCE=$((INDEX + 1))

        # Find line numbers using grep
        REPO_LINE=$(grep -n "repo:" "$TEMPLATE_FILE" | cut -d: -f1 | sed -n "${OCCURRENCE}p")
        CHART_LINE=$(grep -n "chart:" "$TEMPLATE_FILE" | cut -d: -f1 | sed -n "${OCCURRENCE}p")
        VERSION_LINE=$(grep -n "version:" "$TEMPLATE_FILE" | cut -d: -f1 | sed -n "${OCCURRENCE}p")

        # Update the lines in the file
        sed -i \
          -e "${REPO_LINE}s|repo: .*$|repo: ${REPO_URL}|" \
          -e "${CHART_LINE}s|chart: .*$|chart: ${CHART_NAME#*/}|" \
          -e "${VERSION_LINE}s|version: .*$|version: ${LATEST_VERSION}|" \
          "$TEMPLATE_FILE"
        echo "Updated $TEMPLATE_FILE"
      else
        echo "Template file not found: $TEMPLATE_FILE"
      fi
    fi
  done
done
