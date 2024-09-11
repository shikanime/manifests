data "scaleway_object_bucket" "longhorn_backups" {
  name = var.buckets.longhorn_backups
}