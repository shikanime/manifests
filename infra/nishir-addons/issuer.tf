resource "kubernetes_manifest" "issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = var.name
      namespace = "shikanime"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "${var.name}-private-key"
        }
        solvers = [
          {
            dns01 = {
              cloudflare = {
                apiTokenSecretRef = {
                  name = kubernetes_secret.ca_cloudflare_issuer.metadata[0].name
                  key  = "api-token"
                }
              }
            }
          }
        ]
      }
    }
  }
  depends_on = [kubernetes_namespace.shikanime]
}
