data "scaleway_object_bucket" "etcd_backups" {
  name = var.buckets.etcd_backups
}