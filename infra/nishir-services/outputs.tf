output "drive" {
  value = {
    access_key_id     = var.drive.access_key_id
    bucket            = aws_s3_bucket.etcd_backups.bucket
    endpoint          = replace(var.endpoints.s3, "/http[s|]?:\\/\\//", "")
    region            = var.regions.aws_s3_bucket
    secret_access_key = var.drive.secret_access_key
  }
  sensitive = true
}

output "etcd_snapshot" {
  value = {
    access_key_id     = var.etcd_snapshot.access_key_id
    bucket            = aws_s3_bucket.etcd_backups.bucket
    endpoint          = replace(var.endpoints.s3, "/http[s|]?:\\/\\//", "")
    region            = var.regions.aws_s3_bucket
    secret_access_key = var.etcd_snapshot.secret_access_key
  }
  sensitive = true
}

output "longhorn_backupstore" {
  value = {
    access_key_id     = var.longhorn_backupstore.access_key_id
    bucket            = aws_s3_bucket.longhorn_backups.bucket
    endpoint          = var.endpoints.s3
    region            = var.regions.aws_s3_bucket
    secret_access_key = var.longhorn_backupstore.secret_access_key
  }
  sensitive = true
}

output "tailscale_operator" {
  value = {
    client_id     = var.tailscale_operator.client_id
    client_secret = var.tailscale_operator.client_secret
  }
  sensitive = true
}

output "loki" {
  value = {
    password = resource.grafana_cloud_access_policy_token.kubernetes.token
    username = data.grafana_data_source.loki.basic_auth_username
  }
  sensitive = true
}

output "pyroscope" {
  value = {
    password = resource.grafana_cloud_access_policy_token.kubernetes.token
    username = data.grafana_data_source.pyroscope.basic_auth_username
  }
  sensitive = true
}

output "prometheus" {
  value = {
    password = resource.grafana_cloud_access_policy_token.kubernetes.token
    username = data.grafana_data_source.prometheus.basic_auth_username
  }
  sensitive = true
}

output "tempo" {
  value = {
    password = resource.grafana_cloud_access_policy_token.kubernetes.token
    username = data.grafana_data_source.tempo.basic_auth_username
  }
  sensitive = true
}

output "vaultwarden" {
  value = {
    admin_token = var.vaultwarden.admin_token
  }
  sensitive = true
}
