resource "grafana_cloud_access_policy" "kubernetes" {
  region       = var.regions.grafana_cloud_access_policy
  name         = "stack-${var.stack}-integration-${var.name}"
  display_name = "Shikanime Integration ${var.display_name}"

  scopes = [
    "fleet-management:read",
    "logs:write",
    "metrics:read",
    "metrics:write",
    "profiles:write",
    "traces:write"
  ]

  realm {
    type       = "stack"
    identifier = var.stack
  }
}

resource "grafana_cloud_access_policy_token" "kubernetes" {
  region           = var.regions.grafana_cloud_access_policy
  access_policy_id = grafana_cloud_access_policy.kubernetes.policy_id
  name             = "${var.name}-kubernetes"
  display_name     = "${var.display_name} Kubernetes"
}