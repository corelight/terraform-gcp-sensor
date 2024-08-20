resource "google_compute_region_health_check" "traffic_mon_health_check" {
  name               = var.region_health_check_resource_name
  region             = var.region
  check_interval_sec = 30
  timeout_sec        = 30


  http_health_check {
    port         = var.health_check_http_port
    request_path = "/api/system/healthcheck"
    response     = "{\"message\":\"OK\"}"
  }
}

# allow all access from health check ranges
resource "google_compute_firewall" "sensor_health_check_rule" {
  name          = var.firewall_resource_name
  direction     = "INGRESS"
  network       = var.network_mgmt_name
  source_ranges = var.region_probe_source_ranges_cidr

  allow {
    protocol = "tcp"
    ports    = [var.health_check_http_port]
  }

  target_tags = ["sensor"]
}

resource "google_compute_region_backend_service" "traffic_ilb_backend_service" {
  name                  = var.region_backend_service_resource_name
  region                = var.region
  health_checks         = [google_compute_region_health_check.traffic_mon_health_check.id]
  protocol              = "TCP"
  network               = var.network_prod_name
  load_balancing_scheme = "INTERNAL"
  session_affinity      = "NONE"

  backend {
    group = google_compute_region_instance_group_manager.sensor_mig.instance_group
  }
}

resource "google_compute_forwarding_rule" "traffic_forwarding_rule" {
  name                   = var.forwarding_rule_resource_name
  backend_service        = google_compute_region_backend_service.traffic_ilb_backend_service.id
  region                 = var.region
  network                = var.network_prod_name
  subnetwork             = var.subnetwork_mon_name
  is_mirroring_collector = true
  ip_protocol            = "TCP"
  load_balancing_scheme  = "INTERNAL"
  all_ports              = true
}

resource "google_compute_packet_mirroring" "traffic_mirror" {
  name = var.packet_mirroring_resource_name

  network {
    url = var.network_prod_name
  }

  collector_ilb {
    url = google_compute_forwarding_rule.traffic_forwarding_rule.id
  }

  mirrored_resources {
    tags = [var.packet_mirror_network_tag]
  }

  filter {
    direction    = "BOTH"
    ip_protocols = []
    cidr_ranges  = []
  }
}
