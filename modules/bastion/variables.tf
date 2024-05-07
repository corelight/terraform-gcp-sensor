variable "zone" {
  description = "the GCP zone in specified region"
  type        = string
}

variable "instance_size" {
  type        = string
  default     = "e2-medium"
  description = "GCP compute machine type for Fleet Manager"
}

variable "instance_ssh_key_pub" {
  type        = string
  description = "path to the SSH pub key for the instances(s)"
}

variable "instance_ssh_user" {
  type        = string
  default     = "ubuntu"
  description = "the image's default user"
}

variable "image" {
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2004-lts"
  description = "the image from which to initialize this disk"
}

variable "image_disk_size" {
  type        = string
  default     = "120"
  description = "the size of the image in gigabytes"
}

variable "network_mgmt_name" {
  type        = string
  description = "the name or self_link of the mgmt network to attach this interface to"
}

variable "subnetwork_mgmt_name" {
  type        = string
  description = "the name or self_link of the mgmt subnetwork to attach this interface to"
}

variable "instance_resource_name" {
  type        = string
  default     = "corelight-bastion"
  description = "the name of the instance resource"
}
