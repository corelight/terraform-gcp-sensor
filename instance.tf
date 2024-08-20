resource "google_compute_instance_template" "sensor_template" {
  name         = var.instance_template_resource_name
  machine_type = var.instance_size
  tags         = ["allow-ssh", "corelight", "sensor", "allow-health-check"]

  dynamic "service_account" {
    for_each = var.sensor_service_account_email == "" ? toset([]) : toset([1])

    content {
      scopes = ["cloud-platform"]
      email  = var.sensor_service_account_email
    }
  }

  disk {
    source_image = var.image
    disk_size_gb = var.image_disk_size
    auto_delete  = true
    boot         = true
  }

  metadata = {
    ssh-keys  = "${var.instance_ssh_user}:${file(var.instance_ssh_key_pub)}"
    user-data = module.sensor_config.cloudinit_config.rendered
  }

  network_interface {
    network    = var.network_mgmt_name
    subnetwork = var.subnetwork_mgmt_name
  }

  network_interface {
    network    = var.network_prod_name
    subnetwork = var.subnetwork_mon_name
  }

  lifecycle {
    create_before_destroy = false
  }
}

resource "google_compute_region_instance_group_manager" "sensor_mig" {
  name               = var.instance_template_group_manager_resource_name
  region             = var.region
  base_instance_name = var.instance_template_group_manager_base_instance_name

  version {
    instance_template = google_compute_instance_template.sensor_template.id
    name              = "Corelight-Sensor"
  }

  auto_healing_policies {
    health_check      = google_compute_region_health_check.traffic_mon_health_check.id
    initial_delay_sec = 600
  }
}

resource "google_compute_region_autoscaler" "sensor_autoscaler" {
  name   = var.region_autoscaler_resource_name
  target = google_compute_region_instance_group_manager.sensor_mig.id

  autoscaling_policy {
    max_replicas    = var.region_autoscaler_policy_max_replicas
    min_replicas    = var.region_autoscaler_policy_min_replicas
    cooldown_period = var.region_autoscaler_policy_cooldown_period

    cpu_utilization {
      target = var.region_autoscaler_policy_cpu_utilization_target
    }
  }
}
