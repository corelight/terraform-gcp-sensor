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

# NSI Out-of-Band Mirroring Outputs (replaces packet_mirroring_id)
output "mirroring_deployment_group_id" {
  value       = google_network_security_mirroring_deployment_group.mirroring_group.id
  description = "ID of the NSI mirroring deployment group (producer side)"
}

output "mirroring_deployment_id" {
  value       = google_network_security_mirroring_deployment.mirroring_deployment.id
  description = "ID of the NSI mirroring deployment (producer side)"
}

output "mirroring_endpoint_group_id" {
  value       = google_network_security_mirroring_endpoint_group.mirroring_endpoint.id
  description = "ID of the NSI mirroring endpoint group (consumer side)"
}

output "vpc_association_ids" {
  value = {
    for k, v in google_network_security_mirroring_endpoint_group_association.vpc_associations :
    k => v.id
  }
  description = "Map of VPC network names to their endpoint group association IDs"
}
