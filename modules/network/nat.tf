resource "google_compute_router" "mgmt_router" {
  name    = var.router_resource_name
  region  = var.region
  network = google_compute_network.mgmt.name
}

resource "google_compute_router_nat" "mon_nat" {
  name                               = var.router_nat_resource_name
  router                             = google_compute_router.mgmt_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
