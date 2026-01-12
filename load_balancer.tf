resource "google_compute_region_health_check" "traffic_mon_health_check" {
  name               = var.region_health_check_resource_name
  project            = var.project_id
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
  project       = var.project_id
  direction     = "INGRESS"
  network       = google_compute_network.sensor_network.id
  source_ranges = var.region_probe_source_ranges_cidr

  allow {
    protocol = "tcp"
    ports    = [var.health_check_http_port]
  }

  target_tags = ["sensor"]
}

resource "google_compute_region_backend_service" "traffic_ilb_backend_service" {
  name                  = var.region_backend_service_resource_name
  project               = var.project_id
  region                = var.region
  health_checks         = [google_compute_region_health_check.traffic_mon_health_check.id]
  protocol              = "UDP" # Must match forwarding rule protocol for NSI mirroring
  network               = google_compute_network.sensor_network.id
  load_balancing_scheme = "INTERNAL"
  session_affinity      = "NONE"


  backend {
    group          = google_compute_region_instance_group_manager.sensor_mig.instance_group
    balancing_mode = "CONNECTION"
  }
}

resource "google_compute_forwarding_rule" "traffic_forwarding_rule" {
  name                   = var.forwarding_rule_resource_name
  project                = var.project_id
  backend_service        = google_compute_region_backend_service.traffic_ilb_backend_service.id
  region                 = var.region
  network                = google_compute_network.sensor_network.id
  subnetwork             = google_compute_subnetwork.mon_subnet.id
  is_mirroring_collector = true
  ip_protocol            = "UDP" # NSI mirroring uses Geneve encapsulation (UDP/6081) to preserve original packets
  load_balancing_scheme  = "INTERNAL"
  all_ports              = true
}

# NSI Out-of-Band Mirroring Resources (replaces traditional packet mirroring)

# Local variables for backward compatibility and ID generation
locals {
  # Use the created network's self_link
  sensor_network_url = google_compute_network.sensor_network.self_link

  # If mirrored_vpcs is empty, don't create any associations (Phase 1)
  # The sensor VPC itself should NOT be mirrored - it's where sensors receive traffic
  vpcs_to_mirror = var.mirrored_vpcs

  # Create a map of VPCs for for_each usage with network name as key
  vpcs_map = {
    for vpc in local.vpcs_to_mirror :
    # Extract network name from self_link or use as-is
    basename(vpc.network) => {
      network        = startswith(vpc.network, "projects/") ? vpc.network : "projects/${coalesce(vpc.project_id, var.project_id)}/global/networks/${vpc.network}"
      network_name   = basename(vpc.network)
      project_id     = coalesce(vpc.project_id, var.project_id)
      association_id = "${basename(vpc.network)}-association"
    }
  }
}

# Producer Side: Mirroring Deployment Group (global)
resource "google_network_security_mirroring_deployment_group" "mirroring_group" {
  mirroring_deployment_group_id = var.mirroring_deployment_group_id
  project                       = var.project_id
  location                      = "global"
  network                       = local.sensor_network_url

  labels = var.mirroring_labels
}

# Producer Side: Mirroring Deployment (zonal, links to ILB)
# Only ONE deployment per forwarding rule. Regional ILB distributes to all zones.
resource "google_network_security_mirroring_deployment" "mirroring_deployment" {
  mirroring_deployment_id = var.mirroring_deployment_id
  project                 = var.project_id
  location                = var.zone

  mirroring_deployment_group = google_network_security_mirroring_deployment_group.mirroring_group.id
  forwarding_rule            = google_compute_forwarding_rule.traffic_forwarding_rule.id

  labels = var.mirroring_labels
}

# Consumer Side: Mirroring Endpoint Group (global, shared across all VPCs)
resource "google_network_security_mirroring_endpoint_group" "mirroring_endpoint" {
  mirroring_endpoint_group_id = var.mirroring_endpoint_group_id
  project                     = var.project_id
  location                    = "global"
  mirroring_deployment_group  = google_network_security_mirroring_deployment_group.mirroring_group.id

  labels = var.mirroring_labels
}

# Consumer Side: Endpoint Group Association (one per VPC)
resource "google_network_security_mirroring_endpoint_group_association" "vpc_associations" {
  for_each = local.vpcs_map

  mirroring_endpoint_group_association_id = each.value.association_id
  project                                 = each.value.project_id
  location                                = "global"

  mirroring_endpoint_group = google_network_security_mirroring_endpoint_group.mirroring_endpoint.id
  network                  = each.value.network

  labels = var.mirroring_labels
}

# NOTE: NSI (Network Security Interface) mirroring is configured through the
# mirroring deployment and endpoint groups above. Traffic mirroring is controlled
# through the NSI resources, not through firewall policy rules.
#
# The following firewall policy resources have been removed because:
# 1. Network firewall policy rules don't support "mirror" as an action
# 2. NSI mirroring handles traffic interception automatically once the endpoint
#    group associations are created
#
# If additional traffic filtering is needed, it should be implemented as
# standard allow/deny firewall rules separate from the mirroring configuration.
