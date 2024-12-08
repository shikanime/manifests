locals {
  backup_target = "s3://${cloudflare_r2_bucket.longhorn_backups.name}@${cloudflare_r2_bucket.longhorn_backups.location}/"
}

resource "cloudflare_r2_bucket" "longhorn_backups" {
  account_id = var.account
  name       = "${var.name}-longhorn-backups"
  location   = "WEUR"
}

resource "cloudflare_r2_bucket" "etcd_backups" {
  account_id = var.account
  name       = "${var.name}-etcd-backups"
  location   = "WEUR"
}
