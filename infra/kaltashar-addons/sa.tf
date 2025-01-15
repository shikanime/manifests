module "service_accounts" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "~> 4.0"

  project_id    = var.project
  prefix        = var.name
  names         = ["airflow", "airflow-worker"]
  display_name  = "Airflow Service Account"
  generate_keys = true
  project_roles = [
    "${var.project}=>roles/bigquery.dataEditor",
  ]
}
