resource "google_compute_network" "pcf-virt-net" {
  name = "${var.prefix}-virt-net"
  auto_create_subnetworks = false
}

// Ops Manager & Jumpbox
resource "google_compute_subnetwork" "subnet-ops-manager" {
  name          = "${var.prefix}-subnet-infrastructure-${var.gcp_region}"
  ip_cidr_range = "192.168.101.0/26"
  network       = "${google_compute_network.pcf-virt-net.self_link}"
}

// ERT
resource "google_compute_subnetwork" "subnet-ert" {
  name          = "${var.prefix}-subnet-pks-${var.gcp_region}"
  ip_cidr_range = "192.168.16.0/22"
  network       = "${google_compute_network.pcf-virt-net.self_link}"
}

// Services Tile
resource "google_compute_subnetwork" "subnet-services-1" {
  name          = "${var.prefix}-subnet-services-${var.gcp_region}"
  ip_cidr_range = "192.168.20.0/22"
  network       = "${google_compute_network.pcf-virt-net.self_link}"
}
