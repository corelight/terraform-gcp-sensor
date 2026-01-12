# VPC Networks and Subnets for Corelight Sensors
# Note: GCP requires NICs to be on different VPCs, so we create two separate networks

# Create management VPC network (for eth0 - SSH, management, Fleet)
resource "google_compute_network" "mgmt_network" {
  name                    = var.network_mgmt_name != "" ? var.network_mgmt_name : "${var.sensor_network_name}-mgmt"
  project                 = var.project_id
  auto_create_subnetworks = false
  description             = "Management VPC network for Corelight sensors"
}

# Create monitoring VPC network (for eth1 - mirrored traffic)
resource "google_compute_network" "sensor_network" {
  name                    = var.sensor_network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  description             = "Monitoring VPC network for Corelight sensors to receive mirrored traffic"
}

# Create management subnet in management VPC
resource "google_compute_subnetwork" "mgmt_subnet" {
  name          = var.subnetwork_mgmt_name
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.mgmt_network.id
  ip_cidr_range = var.subnetwork_mgmt_cidr
  description   = "Management subnet for Corelight sensors"
}

# Create monitoring subnet in monitoring VPC
resource "google_compute_subnetwork" "mon_subnet" {
  name          = var.subnetwork_mon_name
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.sensor_network.id
  ip_cidr_range = var.subnetwork_mon_cidr
  description   = "Monitoring subnet for Corelight sensors to receive mirrored traffic"
}

# Allow SSH from IAP (Identity-Aware Proxy) for management network
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.network_mgmt_name != "" ? var.network_mgmt_name : "${var.sensor_network_name}-mgmt"}-allow-iap-ssh"
  project = var.project_id
  network = google_compute_network.mgmt_network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP source ranges
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["allow-ssh"]

  description = "Allow SSH access from Identity-Aware Proxy"
}

# Allow Geneve-encapsulated mirrored traffic for NSI out-of-band mirroring
# NSI mirroring uses Geneve protocol (UDP port 6081) to deliver mirrored packets
resource "google_compute_firewall" "allow_geneve" {
  name    = "${var.sensor_network_name}-allow-geneve"
  project = var.project_id
  network = google_compute_network.sensor_network.name

  allow {
    protocol = "udp"
    ports    = ["6081"]
  }

  # Allow from anywhere - mirrored traffic comes from GCP infrastructure
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["sensor"]

  description = "Allow Geneve-encapsulated mirrored traffic (UDP 6081) for NSI out-of-band mirroring"
}
