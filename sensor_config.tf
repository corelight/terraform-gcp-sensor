module "sensor_config" {
  source = "github.com/corelight/terraform-config-sensor?ref=v0.1.0"

  fleet_community_string = var.community_string
  fleet_token            = var.fleet_token
  fleet_url              = var.fleet_url
  fleet_server_sslname   = var.fleet_server_sslname
  fleet_http_proxy       = var.fleet_http_proxy
  fleet_https_proxy      = var.fleet_https_proxy
  fleet_no_proxy         = var.fleet_no_proxy

  sensor_license                               = var.license_key
  sensor_management_interface_name             = "eth0"
  sensor_monitoring_interface_name             = "eth1"
  sensor_health_check_probe_source_ranges_cidr = var.region_probe_source_ranges_cidr
  subnetwork_monitoring_cidr                   = var.subnetwork_mon_cidr
  subnetwork_monitoring_gateway                = var.subnetwork_mon_gateway
  enrichment_enabled                           = var.enrichment_bucket_name != ""
  enrichment_cloud_provider_name               = "gcp"
  enrichment_bucket_name                       = var.enrichment_bucket_name
}
