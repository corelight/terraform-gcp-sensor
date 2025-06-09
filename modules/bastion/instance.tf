resource "google_compute_instance" "bastion_instance" {
  name         = var.instance_resource_name
  machine_type = var.instance_size
  zone         = var.zone
  tags         = ["allow-ssh", "allow-https", "corelight", "bastion"]

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.image_disk_size
    }
  }

  metadata = {
    ssh-keys = "${var.instance_ssh_user}:${file(var.instance_ssh_key_pub)}"
  }

  network_interface {
    network    = var.network_mgmt_name
    subnetwork = var.subnetwork_mgmt_name
    access_config {
      network_tier = "STANDARD"
    }
  }

  lifecycle {
    create_before_destroy = false
  }
}
