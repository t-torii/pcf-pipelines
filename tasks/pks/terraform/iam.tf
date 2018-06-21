resource "google_service_account" "opsman_service_account" {
  account_id   = "${var.env_name}-opsman"
  display_name = "${var.env_name} Ops Manager VM Service Account"
}
