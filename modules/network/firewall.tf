# allow ssh traffic to mgmt (default is inbound)
resource "google_compute_firewall" "allow_ssh_to_mgmt" {
  name      = var.firewall_allow_ssh_resource_name
  direction = "INGRESS"
  network   = google_compute_network.mgmt.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.network_mgmt_firewall_allow_source_ranges
  target_tags   = ["allow-ssh"]
}

# allow internal SSH traffic in mgmt network
resource "google_compute_firewall" "allow_internal" {
  name      = var.firewall_allow_internal_resource_name
  direction = "INGRESS"
  network   = google_compute_network.mgmt.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.subnetwork_mgmt_cidr]
  target_tags   = ["allow-ssh"]
}
