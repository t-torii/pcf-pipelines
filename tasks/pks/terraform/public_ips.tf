// Static IP address for OpsManager
resource "google_compute_address" "opsman" {
  name = "${var.prefix}-opsman"
}
