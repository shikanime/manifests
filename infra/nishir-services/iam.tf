resource "grafana_cloud_access_policy" "kubernetes" {
  region       = var.regions.grafana_cloud_access_policy
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
  region           = var.regions.grafana_cloud_access_policy
  access_policy_id = grafana_cloud_access_policy.kubernetes.policy_id
  name             = "${var.name}-kubernetes"
  display_name     = "${var.display_name} Kubernetes"
}

resource "cloudflare_api_token" "cert_manager" {
  name = "${var.name}-cert-manager"
  policies = [
    {
      effect = "allow"
      permission_groups = [
        for permission_groups in data.cloudflare_api_token_permissions_groups_list.default.result :
        { id = permission_groups.id } if permission_groups.name == "DNS Write"
      ]
      resources = {
        "com.cloudflare.api.account.zone.*" = "*"
      }
    }
  ]
}

data "cloudflare_api_token_permissions_groups_list" "default" {
  account_id = var.account
}
