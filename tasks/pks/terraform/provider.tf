provider "google" {
  project = "${var.gcp_proj_id}"
  region  = "${var.gcp_region}"
  version = "1.9"
  credentials = "${var.service_account_key}"
}

provider "random" {
  version = "1.2"
}
