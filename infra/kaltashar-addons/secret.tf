resource "random_password" "airflow_webserver_secret_key" {
  length  = 14
  special = false
}

resource "kubernetes_secret" "airflow_webserver_secret_key" {
  metadata {
    name      = "airflow-webserver-secret-key"
    namespace = "airflow"
  }
  data = {
    webserver-secret-key = random_password.airflow_webserver_secret_key.result
  }
  type = "Opaque"
}

resource "kubernetes_secret" "airflow_conn_google_cloud" {
  metadata {
    name      = "airflow-conn-google-cloud"
    namespace = "airflow"
  }
  data = {
    AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT = jsonencode({
      conn_type = "google_cloud_platform"
      extra = {
        key_path = "/var/secrets/google/key.json"
        scope    = "https://www.googleapis.com/auth/cloud-platform"
        project  = var.project
      }
    })
  }
}

resource "kubernetes_secret" "airflow_worker_service_account" {
  metadata {
    name      = "airflow-worker-service-account"
    namespace = "airflow"
  }
  data = {
    "key.json" = module.service_accounts.keys["airflow-worker"]
  }
}

resource "kubernetes_secret" "airflow_executor_service_account" {
  metadata {
    name      = "airflow-executor-service-account"
    namespace = "airflow"
  }
  data = {
    "key.json" = module.service_accounts.keys["airflow-executor"]
  }
}