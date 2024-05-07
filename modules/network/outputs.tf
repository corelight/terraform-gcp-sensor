output "firewall_allow_ssh_id" {
  value = google_compute_firewall.allow_ssh_to_mgmt.id
}

output "firewall_allow_internal_id" {
  value = google_compute_firewall.allow_internal.id
}

output "router_mgmt_id" {
  value = google_compute_router.mgmt_router.id
}

output "router_nat_id" {
  value = google_compute_router_nat.mon_nat.id
}

output "network_mgmt_id" {
  value = google_compute_network.mgmt.id
}

output "network_mgmt_name" {
  value = google_compute_network.mgmt.name
}

output "network_prod_id" {
  value = google_compute_network.prod.id
}

output "network_prod_name" {
  value = google_compute_network.prod.name
}

output "subnetwork_mgmt_id" {
  value = google_compute_subnetwork.mgmt_subnet.id
}

output "subnetwork_mgmt_name" {
  value = google_compute_subnetwork.mgmt_subnet.name
}

output "subnetwork_mon_id" {
  value = google_compute_subnetwork.mon_subnet.id
}

output "subnetwork_mon_name" {
  value = google_compute_subnetwork.mon_subnet.name
}
