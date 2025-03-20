resource "kubernetes_secret" "k3s_etcd_snapshot" {
  metadata {
    name      = "k3s-etcd-snapshot"
    namespace = "kube-system"
  }

  type = "Opaque"

  data = {
    etcd-s3-access-key = var.etcd_snapshot.access_key_id
    etcd-s3-bucket     = var.etcd_snapshot.bucket
    etcd-s3-endpoint   = var.etcd_snapshot.endpoint
    etcd-s3-region     = var.etcd_snapshot.region
    etcd-s3-secret-key = var.etcd_snapshot.secret_access_key
  }
}
