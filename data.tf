data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-config/build.tpl", {
      api_password = var.sensor_community_string
      license      = var.sensor_license
      mgmt_int     = "eth0"
      mon_int      = "eth1"
      health_port  = var.health_check_http_port
      mon_subnet   = var.subnetwork_mon_cidr
      mon_gateway  = var.subnetwork_mon_gateway
      probe_ranges = var.region_probe_source_ranges_cidr
    })
    filename = "sensor-build.yaml"
  }
}
