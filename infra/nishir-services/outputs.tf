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
