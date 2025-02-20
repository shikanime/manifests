output "tailscale_operator" {
  value = {
    client_id     = var.tailscale_operator.client_id
    client_secret = var.tailscale_operator.client_secret
  }
  sensitive = true
}

output "longhorn_backupstore" {
  value = {
    backup_target     = local.longhorn_backup_target
    access_key_id     = var.longhorn_backupstore.access_key
    secret_access_key = var.longhorn_backupstore.secret_key
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

output "vaultwarden" {
  value = {
    admin_token = var.vaultwarden.admin_token
  }
  sensitive = true
}
