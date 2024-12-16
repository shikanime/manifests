data "cloudflare_api_token_permission_groups" "default" {}

resource "cloudflare_api_token" "longhorn_backupstore" {
  name = "${var.display_name} Longhorn Backupstore"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.default.account["Workers R2 Storage Read"],
      data.cloudflare_api_token_permission_groups.default.account["Workers R2 Storage Write"],
    ]
    resources = {
      "com.cloudflare.edge.r2.bucket.${var.account}_default_${cloudflare_r2_bucket.longhorn_backups.id}" = "*"
    }
  }
}

resource "cloudflare_api_token" "etcd_snapshot" {
  name = "${var.display_name} ETCD Snapshot"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.default.account["Workers R2 Storage Read"],
      data.cloudflare_api_token_permission_groups.default.account["Workers R2 Storage Write"],
    ]
    resources = {
      "com.cloudflare.edge.r2.bucket.${var.account}_default_${cloudflare_r2_bucket.etcd_backups.id}" = "*"
    }
  }
}

resource "grafana_cloud_access_policy" "kubernetes" {
  region       = "eu"
  name         = "stack-${var.sack}-integration-${var.name}"
  display_name = "Shikanime Integration ${var.display_name}"

  scopes = [
    "metrics:read",
    "logs:write",
    "metrics:write",
    "traces:write"
  ]

  realm {
    type       = "stack"
    identifier = var.sack
  }
}

resource "grafana_cloud_access_policy_token" "kubernetes" {
  region           = "eu"
  access_policy_id = grafana_cloud_access_policy.kubernetes.policy_id
  name             = "${var.name}-kubernetes"
  display_name     = "${var.display_name} Kubernetes"
}
