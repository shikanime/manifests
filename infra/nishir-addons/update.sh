#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Define an array of charts to check
declare -A CHARTS=(
  ["cert_manager"]="jetstack/cert-manager"
  ["grafana_monitoring"]="grafana/k8s-monitoring"
  ["longhorn"]="longhorn/longhorn"
  ["nfd"]="node-feature-discovery/node-feature-discovery"
  ["tailscale"]="tailscale/tailscale-operator"
  ["vpa"]="fairwinds/vpa"
)

declare -A REPOS=(
  ["fairwinds"]="https://charts.fairwinds.com/stable"
  ["grafana"]="https://grafana.github.io/helm-charts"
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

declare -a CHART_VERSIONS=()
for CHART_NAME in "${CHARTS[@]}"; do
  echo "Checking for updates for $CHART_NAME..."

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

    KEY=""
    for k in "${!CHARTS[@]}"; do
      [[ ${CHARTS[$k]} == "$CHART_NAME" ]] && KEY="$k"
    done
    REPO_URL="${REPOS[${CHART_NAME%%/*}]}"
    CHART_VERSIONS+=("\"$KEY\": {\"spec\": {\"version\": \"$LATEST_VERSION\", \"repo\": \"$REPO_URL\", \"chart\": \"${CHART_NAME#*/}\"}}")
  fi
done

echo "{\"kubernetes_manifest\": {$(
  IFS=,
  echo "${CHART_VERSIONS[*]}"
)}}" | jq . >"$(dirname "$0")/manifest.json"
