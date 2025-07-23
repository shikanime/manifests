#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Define an array of charts to check
CHARTS=(
  "capi-operator/cluster-api-operator"
  "descheduler/descheduler"
  "jetstack/cert-manager"
  "grafana/k8s-monitoring"
  "longhorn/longhorn"
  "node-feature-discovery/node-feature-discovery"
  "fairwinds/vpa"
)

declare -A REPOS=(
  ["capi-operator"]="https://kubernetes-sigs.github.io/cluster-api-operator"
  ["descheduler"]="https://kubernetes-sigs.github.io/descheduler"
  ["fairwinds"]="https://charts.fairwinds.com/stable"
  ["grafana"]="https://grafana.github.io/helm-charts"
  ["jetstack"]="https://charts.jetstack.io"
  ["longhorn"]="https://charts.longhorn.io"
  ["node-feature-discovery"]="https://kubernetes-sigs.github.io/node-feature-discovery/charts"
)

# Add each repository to helm using the repo name and URL from REPOS array
for REPO_NAME in "${!REPOS[@]}"; do
  REPO_URL="${REPOS[$REPO_NAME]}"
  helm repo add "$REPO_NAME" "$REPO_URL" &>/dev/null &
done

wait

# Update the repository information
helm repo update

# Process manifests in parallel
for INDEX in "${!CHARTS[@]}"; do
  CHART_NAME=${CHARTS[$INDEX]}
  echo "[${CHART_NAME}] Checking for updates for ${CHARTS[$INDEX]}..."

  LATEST_VERSION=$(
    helm search repo "$CHART_NAME" --output json |
      jq -r 'map(select(.name == "'"$CHART_NAME"'") | .version | select(test("^[v]?[0-9]+\\.[0-9]+\\.[0-9]+$"))) | last // empty'
  )
  echo "[${CHART_NAME}] Latest version of $CHART_NAME: $LATEST_VERSION"

  if [[ -z $LATEST_VERSION ]]; then
    echo "[${CHART_NAME}] Chart '$CHART_NAME' not found in repository."
  else
    echo "[${CHART_NAME}] Found latest version: $LATEST_VERSION"

    OCCURRENCE=$((INDEX + 1))

    REPO_LINE=$(grep -n "repo            =" "$(dirname "$0")/helmchart.tf" | cut -d: -f1 | sed -n "${OCCURRENCE}p")
    CHART_LINE=$(grep -n "chart           =" "$(dirname "$0")/helmchart.tf" | cut -d: -f1 | sed -n "${OCCURRENCE}p")
    VERSION_LINE=$(grep -n "version         =" "$(dirname "$0")/helmchart.tf" | cut -d: -f1 | sed -n "${OCCURRENCE}p")

    REPO_URL="${REPOS[${CHART_NAME%%/*}]}"
    sed -i \
      -e "${REPO_LINE}s|repo            =.*$|repo            = \"${REPO_URL}\"|" \
      -e "${CHART_LINE}s|chart           =.*$|chart           = \"${CHART_NAME#*/}\"|" \
      -e "${VERSION_LINE}s|version         =.*$|version         = \"${LATEST_VERSION}\"|" \
      "$(dirname "$0")/helmchart.tf"
    echo "[${CHART_NAME}] Updated $(dirname "$0")/helmchart.tf"
  fi
done

wait
