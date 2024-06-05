output "instance_template_id" {
  value = google_compute_instance_template.sensor_template.id
}

output "instance_template_group_manager_id" {
  value = google_compute_region_instance_group_manager.sensor_mig.id
}

output "region_autoscaler_id" {
  value = google_compute_region_autoscaler.sensor_autoscaler.id
}

output "region_health_check_id" {
  value = google_compute_region_health_check.traffic_mon_health_check.id
}

output "firewall_id" {
  value = google_compute_firewall.sensor_health_check_rule.id
}

output "region_backend_service_id" {
  value = google_compute_region_backend_service.traffic_ilb_backend_service.id
}

output "forwarding_rule_id" {
  value = google_compute_forwarding_rule.traffic_forwarding_rule.id
}

output "packet_mirroring_id" {
  value = google_compute_packet_mirroring.traffic_mirror.id
}
