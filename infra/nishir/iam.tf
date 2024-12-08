data "cloudflare_api_token_permission_groups" "default" {}

resource "cloudflare_api_token" "longhorn" {
  name = "nishir-longhorn"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.default.account["Workers R2 Storage Read"],
      data.cloudflare_api_token_permission_groups.default.account["Workers R2 Storage Write"],
    ]
    resources = {
      "com.cloudflare.edge.r2.bucket.${cloudflare_r2_bucket.longhorn_backups.id}" = "*"
    }
  }
}

resource "cloudflare_api_token" "etcd_snapshot" {
  name = "nishir-etcd-snapshot"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.default.account["Workers R2 Storage Read"],
      data.cloudflare_api_token_permission_groups.default.account["Workers R2 Storage Write"],
    ]
    resources = {
      "com.cloudflare.edge.r2.bucket.${cloudflare_r2_bucket.etcd_backups.id}" = "*"
    }
  }
}

resource "grafana_cloud_access_policy" "kubernetes" {
  region       = "eu"
  name         = "${var.stack}-integration-nishir"
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

resource "grafana_cloud_access_policy_token" "kubernetes" {
  region           = "eu"
  access_policy_id = grafana_cloud_access_policy.kubernetes.policy_id
  name             = "nishir-kubernetes"
  display_name     = "Nishir Kubernetes"
}
