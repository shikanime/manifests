#!/bin/bash

# Define an array of charts to check
declare -A CHARTS=(
  ["grafana_monitoring"]="grafana/k8s-monitoring"
  ["tailscale"]="tailscale/tailscale-operator"
  ["longhorn"]="longhorn/longhorn"
)

declare -A REPOS=(
  ["grafana"]="https://grafana.github.io/helm-charts"
  ["tailscale"]="https://pkgs.tailscale.com/helmcharts"
  ["longhorn"]="https://charts.longhorn.io"
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
  # Search for the latest version of the chart
  LATEST_VERSION=$(
    helm search repo "$CHART_NAME" --output json |
      jq -r 'map(.version | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))) | last'
  )

  # Check if the chart was found
  if [[ -z $LATEST_VERSION ]]; then
    echo "Chart '$CHART_NAME' not found in repository."
  else
    KEY=$(for k in "${!CHARTS[@]}"; do [[ ${CHARTS[$k]} == "$CHART_NAME" ]] && echo "$k"; done)
    REPO_URL="${REPOS[${CHART_NAME%%/*}]}"
    CHART_VERSIONS+=("\"$KEY\": {\"spec\": {\"version\": \"$LATEST_VERSION\", \"repo\": \"$REPO_URL\", \"chart\": \"${CHART_NAME#*/}\"}}")
  fi
done

echo "{$(
  IFS=,
  echo "${CHART_VERSIONS[*]}"
)}" | jq . >"$(dirname "$0")/manifest.json"
