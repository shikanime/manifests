resource "random_id" "drive" {
  byte_length = 4
  prefix      = "${var.project}-${var.name}-drive-"
}

resource "aws_s3_bucket" "drive" {
  bucket = random_id.drive.hex
}

resource "random_id" "etcd_backups" {
  byte_length = 4
  prefix      = "${var.project}-${var.name}-etcd-backups-"
}

resource "aws_s3_bucket" "etcd_backups" {
  bucket = random_id.etcd_backups.hex
}

resource "random_id" "longhorn_backups" {
  byte_length = 4
  prefix      = "${var.project}-${var.name}-longhorn-backups-"
}

resource "aws_s3_bucket" "longhorn_backups" {
  bucket = random_id.longhorn_backups.hex
}
