resource "scaleway_iam_api_key" "longhorn" {
  application_id = var.app
  description    = "Longhorn Backups"
}

resource "grafana_cloud_access_policy" "nishir" {
  region       = "eu"
  name         = "stack-370431-integration-nishir"
  display_name = "Shikanime Integration Nishir"

  scopes = [
    "metrics:read",
    "logs:write",
    "metrics:write",
    "traces:write"
  ]

  realm {
    type       = "stack"
    identifier = var.stacks.shikanime
  }
}

resource "grafana_cloud_access_policy_token" "nishir_kubernetes" {
  region           = "eu"
  access_policy_id = grafana_cloud_access_policy.nishir.policy_id
  name             = "nishir-kubernetes"
  display_name     = "Nishir Kubernetes"
}
