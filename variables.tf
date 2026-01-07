variable "project_id" {
  description = "GCP project to deploy Corelight sensor resources"
  type        = string
}

variable "region" {
  type        = string
  description = "the GCP region"
}

variable "zone" {
  type        = string
  description = "the GCP zone for zonal resources"
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
  default     = "500"
  description = "the size of the image in gigabytes"
}

variable "network_mgmt_name" {
  type        = string
  default     = ""
  description = "the name or self_link of the mgmt network. Defaults to sensor_network_name if not specified."
}

variable "subnetwork_mgmt_name" {
  type        = string
  description = "the name or self_link of the mgmt subnetwork to attach this interface to"
}

variable "subnetwork_mgmt_cidr" {
  type        = string
  description = "CIDR range for the management subnetwork (e.g., '10.0.1.0/24')"
}

variable "sensor_network_name" {
  type        = string
  description = "the name or self_link of the network where sensors receive mirrored traffic (monitoring network)"
}

variable "subnetwork_mon_name" {
  type        = string
  description = "the name or self_link of the monitor subnetwork to attach this interface to"
}

variable "fleet_token" {
  type        = string
  sensitive   = true
  description = "The pairing token from the Fleet UI. Must be set if 'fleet_url' is provided"
}

variable "fleet_url" {
  type        = string
  description = "The URL of the fleet instance from the Fleet UI. Must be set if 'fleet_token' is provided"
}

variable "fleet_server_sslname" {
  type        = string
  description = "The SSL hostname for the fleet server"
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

variable "license_key_file_path" {
  description = "Path to file containing your Corelight sensor license key. Optional if fleet_url is configured."
  sensitive   = true
  type        = string
  default     = ""

  validation {
    condition     = var.license_key_file_path != "" || var.fleet_url != ""
    error_message = "Either license_key_file_path (path to license file) must be provided or fleet_url must be configured."
  }
}

variable "community_string" {
  type        = string
  sensitive   = true
  description = "the community string (api string) often times referenced by Fleet"
}

variable "instance_template_resource_name_prefix" {
  type        = string
  default     = "corelight-mig-template-"
  description = "the name prefix of the instance template resource"
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

# NSI Out-of-Band Mirroring Variables (replaces traditional packet mirroring)
variable "mirroring_deployment_group_id" {
  type        = string
  default     = "corelight-mirroring-deployment-group"
  description = "ID for the NSI mirroring deployment group (producer side)"
}

variable "mirroring_deployment_id" {
  type        = string
  default     = "corelight-mirroring-deployment"
  description = "ID for the NSI mirroring deployment (producer side)"
}

variable "mirroring_endpoint_group_id" {
  type        = string
  default     = "corelight-mirroring-endpoint-group"
  description = "ID for the NSI mirroring endpoint group (consumer side, shared across all VPCs)"
}

variable "mirrored_vpcs" {
  type = list(object({
    network       = string
    project_id    = optional(string)
  }))
  default     = []
  description = <<-EOT
    List of VPC networks to mirror traffic from to the Corelight sensors.
    For single VPC deployments, provide one entry. For multi-VPC, provide multiple entries.

    If empty, defaults to mirroring from sensor_network_name.

    Fields:
    - network: Name or self_link of the VPC network to mirror from
    - project_id: (Optional) Project ID if VPC is in different project. Defaults to var.project_id

    Example single VPC:
    mirrored_vpcs = [{
      network = "customer-vpc-1"
    }]

    Example multi-VPC:
    mirrored_vpcs = [
      { network = "customer-vpc-1", project_id = "customer-project-1" },
      { network = "customer-vpc-2", project_id = "customer-project-2" },
      { network = "customer-vpc-3" }
    ]
  EOT
}

variable "mirroring_labels" {
  type        = map(string)
  default     = {}
  description = "Labels to apply to NSI mirroring resources"
}

variable "sensor_service_account_email" {
  description = "The service account email granting the sensor cloud features permission to GCP APIs and services"
  type        = string
  default     = ""
}

variable "fleet_http_proxy" {
  type        = string
  default     = ""
  description = "(optional) the proxy URL for HTTP traffic from the fleet"
}

variable "fleet_https_proxy" {
  type        = string
  default     = ""
  description = "(optional) the proxy URL for HTTPS traffic from the fleet"
}

variable "fleet_no_proxy" {
  type        = string
  default     = ""
  description = "(optional) hosts or domains to bypass the proxy for fleet traffic"
}

# NSI Mirroring Traffic Selection Variables

variable "organization_id" {
  type        = string
  default     = ""
  description = "Organization ID (numeric only, e.g., '536691410123') for referencing org-level security profiles. If not specified, will be derived from the project."
}

variable "security_profile_id" {
  type        = string
  default     = ""
  description = "Full resource ID of the security profile created by org admin. Format: organizations/ORG_ID/locations/global/securityProfiles/PROFILE_NAME. If empty, will be constructed from organization_id and mirroring_profile_name."
}

variable "security_profile_group_id" {
  type        = string
  default     = ""
  description = "Full resource ID of the security profile group created by org admin. Format: organizations/ORG_ID/locations/global/securityProfileGroups/GROUP_NAME. If empty, will be constructed from organization_id and mirroring_profile_group_name."
}

variable "mirroring_profile_name" {
  type        = string
  default     = "corelight-mirror-profile"
  description = "Name for the custom mirroring security profile (used if security_profile_id not provided)"
}

variable "mirroring_profile_group_name" {
  type        = string
  default     = "corelight-mirror-profile-group"
  description = "Name for the security profile group containing the mirroring profile (used if security_profile_group_id not provided)"
}

variable "mirroring_src_ip_ranges" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "Source IP ranges to mirror for ingress traffic"
}

variable "mirroring_dest_ip_ranges" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "Destination IP ranges to mirror for egress traffic"
}
