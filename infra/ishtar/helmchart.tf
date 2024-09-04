resource "kubernetes_manifest" "tailscale_operator" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "tailscale-operator"
      namespace = "kube-system"
    }
    spec = {
      repo            = "https://pkgs.tailscale.com/helmcharts"
      chart           = "tailscale-operator"
      targetNamespace = kubernetes_namespace.tailscale.metadata[0].name
      version         = "1.68.1"
      helmVersion     = "v3"
      bootstrap       = false
      valuesContent = yamlencode({
        apiServerProxyConfig = {
          mode = "true"
        }
        oauth = {
          clientId     = local.tailscale_oauth_client_data.clientId
          clientSecret = local.tailscale_oauth_client_data.clientSecret
        }
        operatorConfig = {
          hostname = "${var.name}-k8s-operator"
        }
      })
    }
  }
  depends_on = [kubernetes_namespace.tailscale]
}
