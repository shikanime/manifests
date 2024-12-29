locals {
  manifest = jsondecode(file("manifest.json"))
}

resource "kubernetes_namespace" "shikanime" {
  metadata {
    name = "shikanime"
  }
}

resource "kubernetes_namespace" "tailscale" {
  metadata {
    name = "tailscale"
  }
}

resource "kubernetes_manifest" "tailscale" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "tailscale"
      namespace = "kube-system"
    }
    spec = {
      repo            = local.manifest.kubernetes_manifest.tailscale.spec.repo
      chart           = local.manifest.kubernetes_manifest.tailscale.spec.chart
      targetNamespace = one(kubernetes_namespace.tailscale.metadata).name
      version         = local.manifest.kubernetes_manifest.tailscale.spec.version
      helmVersion     = "v3"
      bootstrap       = false
      valuesContent = jsonencode({
        oauthSecretVolume = {
          secret = {
            secretName = one(kubernetes_secret.tailscale_operator_oauth_client.metadata).name
          }
        }
      })
    }
  }
}
