resource "b2_application_key" "longhorn_backupstore" {
  key_name = "nishir-longhorn-backupstore"
  capabilities = [
    "deleteFiles",
    "listAllBucketNames",
    "listFiles",
    "readFiles",
    "writeFiles",
  ]
  bucket_id = b2_bucket.longhorn_backups.id
}

resource "b2_application_key" "etcd_snapshot" {
  key_name = "nishir-etcd-snapshot"
  capabilities = [
    "deleteFiles",
    "listAllBucketNames",
    "listFiles",
    "readFiles",
    "writeFiles",
  ]
  bucket_id = b2_bucket.etcd_backups.id
}

data "cloudflare_api_token_permission_groups" "default" {}

resource "cloudflare_api_token" "longhorn_backupstore" {
  name = "Nishir Longhorn Backupstore"

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

resource "grafana_cloud_access_policy" "kubernetes" {
  region       = "eu"
  name         = "stack-${var.sack}-integration-nishir"
  display_name = "Shikanime Integration Nishir"

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
  name             = "nishir-kubernetes"
  display_name     = "Nishir Kubernetes"
}
