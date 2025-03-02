resource "random_id" "etcd_backups" {
  byte_length = 4
  prefix      = "${var.project}-${var.name}-etcd-backups-"
}

resource "aws_s3_bucket" "etcd_backups" {
  bucket = random_id.etcd_backups.hex
}
