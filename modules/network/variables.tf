variable "region" {
  type        = string
  description = "the GCP region"
}

variable "subnetwork_mgmt_cidr" {
  type        = string
  description = "the management subnet for the sensor(s)"
}

variable "subnetwork_mon_cidr" {
  type        = string
  description = "the monitor subnet for the sensor(s)"
}

variable "network_mgmt_firewall_allow_source_ranges" {
  type        = list(any)
  default     = ["0.0.0.0/0"]
  description = "list of source CIDR addresses allowed to access the management subnet"
}

variable "firewall_allow_ssh_resource_name" {
  type        = string
  default     = "corelight-allow-ssh-inbound-to-mgmt"
  description = "the name of the firewall allow ssh resource"
}

variable "firewall_allow_internal_resource_name" {
  type        = string
  default     = "corelight-allow-internal"
  description = "the name of the firewall allow internal resource"
}

variable "router_resource_name" {
  type        = string
  default     = "corelight-mgmt-router"
  description = "the name of the router resource"
}

variable "router_nat_resource_name" {
  type        = string
  default     = "corelight-mgmt-nat"
  description = "the name of the router nat resource"
}

variable "network_mgmt_resource_name" {
  type        = string
  default     = "corelight-mgmt"
  description = "the name of the mgmt network resource"
}

variable "network_prod_resource_name" {
  type        = string
  default     = "corelight-prod"
  description = "the name of the prod network resource"
}

variable "subnetwork_mgmt_resource_name" {
  type        = string
  default     = "corelight-subnet"
  description = "the name of the mgmt subnetwork resource"
}

variable "subnetwork_mon_resource_name" {
  type        = string
  default     = "corelight-mon-subnet"
  description = "the name of the mon subnetwork resource"
}
