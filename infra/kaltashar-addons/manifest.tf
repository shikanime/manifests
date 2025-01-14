locals {
  manifest = jsondecode(file("manifest.json"))
}

resource "kubernetes_namespace" "airflow" {
  metadata {
    name = "airflow"
  }
}

resource "kubernetes_manifest" "airflow" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "airflow"
      namespace = "airflow"
    }
    spec = {
      repo            = local.manifest.kubernetes_manifest.airflow.spec.repo
      chart           = local.manifest.kubernetes_manifest.airflow.spec.chart
      targetNamespace = one(kubernetes_namespace.airflow.metadata).name
      version         = local.manifest.kubernetes_manifest.airflow.spec.version
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
      valuesContent = jsonencode({
        airflow = {
          kubernetesPodTemplate = {
            extraVolumeMounts = [
              {
                name      = "google-application-credentials"
                mountPath = "/var/secrets/google"
              }
            ]
            extraVolumes = [
              {
                name = "google-application-credentials"
                secret = {
                  secretName = "google-application-credentials"
                }
              }
            ]
          }
        }
        workers = {
          extraVolumeMounts = [
            {
              name      = "google-application-credentials"
              mountPath = "/var/secrets/google"
            }
          ]
          extraVolumes = [
            {
              name = "google-application-credentials"
              secret = {
                secretName = "google-application-credentials"
              }
            }
          ]
        }
        secrets = [
          {
            envName    = "AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT"
            secretName = "airflow-connection-google-cloud"
            secretKey  = "AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT"
          }
        ]
        webserverSecretKeySecretName = kubernetes_secret.airflow_webserver_secret_key.metadata.0.name
      })
    }
  }
}