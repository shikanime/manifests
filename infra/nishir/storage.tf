locals {
  longhorn_b2_backup_target = "s3://${b2_bucket.longhorn_backups.bucket_name}@${local.longhorn_b2_backup_region}/"
  longhorn_b2_backup_region = "eu-central"
  longhorn_cf_backup_target = "s3://${cloudflare_r2_bucket.longhorn_backups.name}@${cloudflare_r2_bucket.longhorn_backups.location}/"
}

resource "cloudflare_r2_bucket" "longhorn_backups" {
  account_id = var.account
  name       = "nishir-longhorn-backups"
  location   = "WEUR"
}

resource "cloudflare_r2_bucket" "etcd_backups" {
  account_id = var.account
  name       = "nishir-etcd-backups"
  location   = "WEUR"
}

resource "b2_bucket" "longhorn_backups" {
  bucket_name = "shikanime-studio-nishir-longhorn-backups"
  bucket_type = "allPrivate"
  default_server_side_encryption {
    algorithm = "AES256"
    mode      = "SSE-B2"
  }
}

resource "b2_bucket" "etcd_backups" {
  bucket_name = "shikanime-studio-nishir-etcd-backups"
  bucket_type = "allPrivate"
  default_server_side_encryption {
    algorithm = "AES256"
    mode      = "SSE-B2"
  }
}