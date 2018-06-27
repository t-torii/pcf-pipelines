// Go Router Health check
resource "google_compute_http_health_check" "cf-gorouter" {
  name                = "${var.prefix}-gorouter"
  port                = 8080
  request_path        = "/health"
  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 10
  unhealthy_threshold = 2
}


// GoRouter target pool
resource "google_compute_target_pool" "cf-gorouter" {
  name = "${var.prefix}-wss-logs"

  health_checks = [
    "${google_compute_http_health_check.cf-gorouter.name}",
  ]
}

// Doppler forwarding rule
resource "google_compute_forwarding_rule" "cf-gorouter" {
  name        = "${var.prefix}-gorouter-wss"
  target      = "${google_compute_target_pool.cf-gorouter.self_link}"
  port_range  = "443"
  ip_protocol = "TCP"
  ip_address  = "${google_compute_address.ssh-and-doppler.address}"
}
