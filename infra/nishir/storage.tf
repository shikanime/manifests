locals {
  backup_target = "s3://${cloudflare_r2_bucket.longhorn_backups.name}@${cloudflare_r2_bucket.longhorn_backups.location}/"
}

resource "cloudflare_r2_bucket" "longhorn_backups" {
  account_id = "d4e789904d6943d8cd524e19c5cb36bd"
  name       = "nishir-longhorn-backups"
  location   = "WEUR"
}

resource "cloudflare_r2_bucket" "etcd_backups" {
  account_id = "d4e789904d6943d8cd524e19c5cb36bd"
  name       = "nishir-etcd-backups"
  location   = "WEUR"
}
