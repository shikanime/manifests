resource "terraform_data" "nishir" {
  triggers_replace = {
    tailscale_content              = local_file.tailscale.content
    longhorn_content               = local_file.longhorn.content
    grafana_monitoring_content     = local_file.grafana_monitoring.content
    vpa_content                    = local_file.vpa.content
    cert_manager_content           = local_file.cert_manager.content
    node_feature_discovery_content = local_file.node_feature_discovery.content
  }

  connection {
    type = "ssh"
    user = "root"
    host = "nishir"
  }

  provisioner "file" {
    content     = local_file.tailscale.content
    destination = "/mnt/nishir/rancher/k3s/server/manifests/tailscale.yaml"
  }

  provisioner "file" {
    content     = local_file.longhorn.content
    destination = "/mnt/nishir/rancher/k3s/server/manifests/longhorn.yaml"
  }

  provisioner "file" {
    content     = local_file.grafana_monitoring.content
    destination = "/mnt/nishir/rancher/k3s/server/manifests/grafana-monitoring.yaml"
  }

  provisioner "file" {
    content     = local_file.vpa.content
    destination = "/mnt/nishir/rancher/k3s/server/manifests/vpa.yaml"
  }

  provisioner "file" {
    content     = local_file.cert_manager.content
    destination = "/mnt/nishir/rancher/k3s/server/manifests/cert-manager.yaml"
  }

  provisioner "file" {
    content     = local_file.node_feature_discovery.content
    destination = "/mnt/nishir/rancher/k3s/server/manifests/node-feature-discovery.yaml"
  }
}
