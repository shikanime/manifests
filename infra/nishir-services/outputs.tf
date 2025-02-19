output "tailscale" {
  value = {
    client_id     = local.tailscale_operator_oauth_client_data.client_id
    client_secret = local.tailscale_operator_oauth_client_data.client_secret
  }
  sensitive = true
}

output "longhorn" {
  value = {
    backup_target     = local.longhorn_backup_target
    access_key_id     = local.longhorn_backupstore_s3_creds_data.access_key_id
    secret_access_key = local.longhorn_backupstore_s3_creds_data.secret_access_key
    endpoints         = var.endpoints.s3
  }
  sensitive = true
}

output "prometheus" {
  value = {
    endpoint = var.endpoints.prometheus
    password = resource.grafana_cloud_access_policy_token.kubernetes.token
    username = data.grafana_data_source.prometheus.basic_auth_username
  }
  sensitive = true
}

output "loki" {
  value = {
    endpoint = var.endpoints.loki
    password = resource.grafana_cloud_access_policy_token.kubernetes.token
    username = data.grafana_data_source.loki.basic_auth_username
  }
  sensitive = true
}

output "tempo" {
  value = {
    endpoint = var.endpoints.tempo
    password = resource.grafana_cloud_access_policy_token.kubernetes.token
    username = data.grafana_data_source.tempo.basic_auth_username
  }
  sensitive = true
}
