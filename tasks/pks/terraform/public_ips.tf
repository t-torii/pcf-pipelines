// Static IP address for OpsManager
resource "google_compute_address" "opsman" {
  name = "${var.prefix}-opsman"
}

// Global IP for PCF API & Apps
resource "google_compute_global_address" "pcf" {
  name = "${var.prefix}-global-pcf"
}

// Static IP address for forwarding rule for sshproxy & doppler
resource "google_compute_address" "ssh-and-doppler" {
  name = "${var.prefix}-ssh-and-doppler"
}
