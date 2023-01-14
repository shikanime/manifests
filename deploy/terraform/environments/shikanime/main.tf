module "infrastructure" {
  source  = "../../modules/infrastructure"
  name    = var.name
  project = var.project
  region  = var.region
  zone    = var.zone
}
