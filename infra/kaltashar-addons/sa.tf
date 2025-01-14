module "service_accounts" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "~> 4.0"

  project_id    = var.project
  prefix        = var.name
  names         = ["airflow", "airflow-worker"]
  generate_keys = true
}
