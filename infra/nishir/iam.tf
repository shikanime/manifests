data "cloudflare_api_token_permission_groups" "default" {}

resource "cloudflare_api_token" "nishir" {
  name = "nishir"

  policy = [
    {
      permission_groups = [
        data.cloudflare_api_token_permission_groups.default.account["Workers R2 Storage Read"],
        data.cloudflare_api_token_permission_groups.default.account["Workers R2 Storage Write"],
      ]
      resources = {
        "com.cloudflare.api.account.${var.account}" = "*"
      }
    }
  ]
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
    identifier = var.stack
  }
}

resource "grafana_cloud_access_policy_token" "nishir_kubernetes" {
  region           = "eu"
  access_policy_id = grafana_cloud_access_policy.nishir.policy_id
  name             = "nishir-kubernetes"
  display_name     = "Nishir Kubernetes"
}
