locals {
  backup_target = "s3://${data.cloudflare_r2_bucket.longhorn_backups.name}@${data.cloudflare_r2_bucket.longhorn_backups.location}/"
}

data "cloudflare_r2_bucket" "longhorn_backups" {
  account_id = var.account
  name       = var.buckets.longhorn_backups
}
