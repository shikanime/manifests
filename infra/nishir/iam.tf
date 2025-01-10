resource "grafana_cloud_access_policy" "kubernetes" {
  region       = "eu"
  name         = "stack-${var.stack}-integration-${var.name}"
  display_name = "Shikanime Integration ${var.display_name}"

  scopes = [
    "metrics:read",
    "logs:write",
    "metrics:write",
    "traces:write"
  ]

  realm {
    type       = "stack"
    identifier = var.stack
  }
}

resource "grafana_cloud_access_policy_token" "kubernetes" {
  region           = "eu"
  access_policy_id = grafana_cloud_access_policy.kubernetes.policy_id
  name             = "${var.name}-kubernetes"
  display_name     = "${var.display_name} Kubernetes"
}
