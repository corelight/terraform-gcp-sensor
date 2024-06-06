variable "region" {
  type        = string
  description = "the GCP region"
}

variable "zone" {
  description = "the GCP zone in specified region"
  type        = string
}

variable "instance_size" {
  type        = string
  default     = "e2-standard-8"
  description = "GCP compute machine type for Fleet Manager"
}

variable "instance_ssh_key_pub" {
  type        = string
  description = "path to the SSH pub key for the instances(s)"
}

variable "instance_ssh_user" {
  type        = string
  default     = "ec2-user"
  description = "the image's default user"
}

variable "image" {
  type        = string
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

variable "network_prod_name" {
  type        = string
  description = "the name or self_link of the prod network to attach this interface to"
}

variable "subnetwork_mon_name" {
  type        = string
  description = "the name or self_link of the monitor subnetwork to attach this interface to"
}

variable "subnetwork_mgmt_cidr" {
  type        = string
  description = "the management subnet for the sensor(s)"
}

variable "region_probe_source_ranges_cidr" {
  type        = list(string)
  default     = ["130.211.0.0/22", "35.191.0.0/16"]
  description = "the GCP health check probe ranges, see https://cloud.google.com/load-balancing/docs/health-check-concepts#ip-ranges"
}

variable "region_autoscaler_policy_max_replicas" {
  type        = number
  default     = 3
  description = "the maximum number of instances that the autoscaler can scale up to"
}

variable "region_autoscaler_policy_min_replicas" {
  type        = number
  default     = 1
  description = "ghe minimum number of replicas that the autoscaler can scale down to"
}

variable "region_autoscaler_policy_cooldown_period" {
  type        = number
  default     = 600
  description = "the number of seconds that the autoscaler should wait before it starts collecting information from a new instance"
}

variable "region_autoscaler_policy_cpu_utilization_target" {
  type        = number
  default     = 0.4
  description = "the target CPU utilization that the autoscaler should maintain"
}

variable "subnetwork_mon_cidr" {
  type        = string
  description = "the monitor subnet for the sensor(s)"
}

variable "subnetwork_mon_gateway" {
  type        = string
  description = "the monitor subnet's gateway address"
}

variable "health_check_http_port" {
  type        = string
  default     = "41080"
  description = "the port number for the HTTP health check request"
}

variable "license_key" {
  description = "Your Corelight sensor license key"
  type        = string
  sensitive   = true
}

variable "community_string" {
  type        = string
  sensitive   = true
  description = "the community string (api string) often times referenced by Fleet"
}

variable "instance_template_resource_name" {
  type        = string
  default     = "corelight-mig-template"
  description = "the name of the instance template resource"
}

variable "instance_template_group_manager_resource_name" {
  type        = string
  default     = "corelight-mig-manager"
  description = "the name of the instance group manager resource"
}

variable "instance_template_group_manager_base_instance_name" {
  type        = string
  default     = "corelight"
  description = "the base instance name to use for instances in this group"
}

variable "region_autoscaler_resource_name" {
  type        = string
  default     = "corelight-autoscale"
  description = "the name of the qutoscaler resource"
}

variable "region_health_check_resource_name" {
  type        = string
  default     = "corelight-traffic-monitor-health-check"
  description = "the name of the health check resource"
}

variable "firewall_resource_name" {
  type        = string
  default     = "corelight-sensor-health-check-rule"
  description = "the name of the firewall resource"
}

variable "region_backend_service_resource_name" {
  type        = string
  default     = "corelight-traffic-ilb-backend-service"
  description = "the name of the region backend service resource"
}

variable "forwarding_rule_resource_name" {
  type        = string
  default     = "corelight-traffic-forwarding-rule"
  description = "the name of the forwarding rule resource"
}

variable "packet_mirroring_resource_name" {
  type        = string
  default     = "corelight-traffic-mirroring"
  description = "the name of the packet mirroring resource"
}

# Enrichment Service
variable "enrichment_enabled" {
  description = "(optional) if cloud enrichment should enabled at time of sensor deployment"
  type        = string
  default     = false
}

variable "enrichment_cloud_provider_name" {
  description = "(optional) the cloud provider name"
  type        = string
  default     = ""
}

variable "enrichment_bucket_name" {
  description = "(optional) the s3 bucket, azure storage container, or gcs bucket name"
  type        = string
  default     = ""
}
