// Core Project Output

output "project" {
  value = "${var.gcp_proj_id}"
}

output "region" {
  value = "${var.gcp_region}"
}

output "azs" {
  value = "${var.gcp_zone_1},${var.gcp_zone_2},${var.gcp_zone_3}"
}

output "deployment-prefix" {
  value = "${var.prefix}-vms"
}

// DNS Output

output "ops_manager_public_ip" {
  value = "${google_compute_instance.ops-manager.network_interface.0.access_config.0.assigned_nat_ip}"
}

// Network Output

output "network_name" {
  value = "${google_compute_network.pcf-virt-net.name}"
}

output "ops_manager_gateway" {
  value = "${google_compute_subnetwork.subnet-ops-manager.gateway_address}"
}

output "ops_manager_cidr" {
  value = "${google_compute_subnetwork.subnet-ops-manager.ip_cidr_range}"
}

output "ops_manager_subnet" {
  value = "${google_compute_subnetwork.subnet-ops-manager.name}"
}

output "ert_gateway" {
  value = "${google_compute_subnetwork.subnet-ert.gateway_address}"
}

output "ert_cidr" {
  value = "${google_compute_subnetwork.subnet-ert.ip_cidr_range}"
}

output "ert_subnet" {
  value = "${google_compute_subnetwork.subnet-ert.name}"
}

output "svc_net_1_gateway" {
  value = "${google_compute_subnetwork.subnet-services-1.gateway_address}"
}

output "svc_net_1_cidr" {
  value = "${google_compute_subnetwork.subnet-services-1.ip_cidr_range}"
}

output "svc_net_1_subnet" {
  value = "${google_compute_subnetwork.subnet-services-1.name}"
}

output "pub_ip_opsman" {
  value = "${google_compute_address.opsman.address}"
}
