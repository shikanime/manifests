resource "scaleway_iam_api_key" "longhorn" {
  application_id = var.app
  description    = "Longhorn Backups"
}
