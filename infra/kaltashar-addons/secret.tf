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

resource "kubernetes_secret" "airflow_service_account" {
  metadata {
    name      = "airflow-service-account"
    namespace = "airflow"
  }
  data = {
    "key.json" = module.service_accounts.keys["airflow"]
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

resource "tls_private_key" "github_deploy_key" {
  algorithm = "ED25519"
}

resource "kubernetes_secret" "airflow_ssh_key" {
  metadata {
    name      = "airflow-ssh-key"
    namespace = "airflow"
  }
  data = {
    gitSshKey = tls_private_key.github_deploy_key.private_key_openssh
  }
}

data "github_repository" "default" {
  full_name = var.repository
}

resource "github_repository_deploy_key" "airflow" {
  title      = "${var.display_name} Airflow"
  repository = data.github_repository.default.id
  key        = tls_private_key.github_deploy_key.public_key_openssh
  read_only  = true
}
