data "grafana_data_source" "prometheus" {
  name = "grafanacloud-shikanime-prom"
}

data "grafana_data_source" "loki" {
  name = "grafanacloud-shikanime-logs"
}

data "grafana_data_source" "tempo" {
  name = "grafanacloud-shikanime-traces"
}
