resource "google_service_account" "opsman_service_account" {
  account_id   = "${var.prefix}-opsman"
  display_name = "${var.prefix} Ops Manager VM Service Account"
}
