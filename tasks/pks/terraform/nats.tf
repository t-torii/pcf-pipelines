// NAT Primary
resource "google_compute_instance" "nat-gateway-pri" {
  name           = "${var.prefix}-nat-gateway-pri"
  machine_type   = "g1-small"
  zone           = "${var.gcp_zone_1}"
  can_ip_forward = true
  tags           = ["${var.prefix}-nat-instance", "nat-traverse"]

  boot_disk {
    initialize_params {
      image = "ubuntu-1404-trusty-v20160610"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet-ops-manager.name}"

    access_config {
      // Ephemeral
    }
  }

  metadata_startup_script = <<EOF
  #!/bin/bash
  sudo sysctl -w net.ipv4.ip_forward=1
  sudo sh -c 'echo net.ipv4.ip_forward=1 | sudo tee -a /etc/sysctl.conf > /dev/null'
  sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  EOF
}

resource "google_compute_route" "nat-primary" {
  name                   = "${var.prefix}-nat-pri"
  dest_range             = "0.0.0.0/0"
  network                = "${google_compute_network.pcf-virt-net.name}"
  next_hop_instance      = "${google_compute_instance.nat-gateway-pri.name}"
  next_hop_instance_zone = "${var.gcp_zone_1}"
  priority               = 800
  tags                   = ["${var.prefix}"]
}
