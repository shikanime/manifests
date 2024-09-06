data "grafana_data_source" "prometheus" {
  name = var.data_sources.prometheus
}

data "grafana_data_source" "loki" {
  name = var.data_sources.loki
}

data "grafana_data_source" "tempo" {
  name = var.data_sources.tempo
}
