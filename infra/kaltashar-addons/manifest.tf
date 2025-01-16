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
      namespace = "kube-system"
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
          executor = "KubernetesExecutor"
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
                  secretName = kubernetes_secret.airflow_service_account.metadata.0.name
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
                secretName = kubernetes_secret.airflow_worker_service_account.metadata.0.name
              }
            }
          ]
        }
        connections = [
          {
            id   = "google_cloud_default",
            type = "google_cloud_platform",
            extra = {
              key_path = "/var/secrets/google/key.json"
              scope    = "https://www.googleapis.com/auth/cloud-platform"
              project  = var.project
            }
          }
        ]
        dags = {
          gitSync = {
            enabled      = true
            repo         = "git@github.com:${var.repository}.git"
            branch       = "main"
            ref          = "main"
            subPath      = ""
            sshKeySecret = kubernetes_secret.airflow_ssh_key.metadata.0.name
            knownHosts   = "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
          }
        }
        webserverSecretKeySecretName = kubernetes_secret.airflow_webserver_secret_key.metadata.0.name
      })
    }
  }
}