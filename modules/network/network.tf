resource "google_compute_network" "mgmt" {
  name                    = var.network_mgmt_resource_name
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = false
}

resource "google_compute_network" "prod" {
  name                    = var.network_prod_resource_name
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "mgmt_subnet" {
  name          = var.subnetwork_mgmt_resource_name
  ip_cidr_range = var.subnetwork_mgmt_cidr
  network       = google_compute_network.mgmt.name
  region        = var.region
}

resource "google_compute_subnetwork" "mon_subnet" {
  name          = var.subnetwork_mon_resource_name
  ip_cidr_range = var.subnetwork_mon_cidr
  network       = google_compute_network.prod.name
  region        = var.region
}
