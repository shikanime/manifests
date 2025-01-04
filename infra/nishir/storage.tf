locals {
  longhorn_backup_target = "s3://${aws_s3_bucket.longhorn_backups.bucket}@fsn1/"
  longhorn_endpoints     = "https://fsn1.your-objectstorage.com"
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

resource "random_id" "longhorn_backups" {
  byte_length = 4
  prefix      = "${var.project}-${var.name}-longhorn-backups-"
}

resource "aws_s3_bucket" "longhorn_backups" {
  bucket = random_id.longhorn_backups.hex
}

resource "random_id" "etcd_backups" {
  byte_length = 4
  prefix      = "${var.project}-${var.name}-etcd-backups-"
}

resource "aws_s3_bucket" "etcd_backups" {
  bucket = random_id.etcd_backups.hex
}
