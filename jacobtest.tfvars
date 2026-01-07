project_id              = "cloud-408817"
region                  = "us-central1"
zone                    = "us-central1-a"

# Custom resource names to avoid conflicts with other stacks
region_health_check_resource_name = "corelight-nsi-health-check"
firewall_resource_name            = "corelight-nsi-health-check-rule"
instance_template_group_manager_resource_name = "corelight-nsi-mig-manager"
region_autoscaler_resource_name   = "corelight-nsi-autoscale"
region_backend_service_resource_name = "corelight-nsi-backend-service"
forwarding_rule_resource_name     = "corelight-nsi-forwarding-rule"
mirroring_deployment_group_id     = "corelight-nsi-deployment-group"
mirroring_deployment_id           = "corelight-nsi-deployment"
mirroring_endpoint_group_id       = "corelight-nsi-endpoint-group"

# Network names - using different names to avoid conflicts
sensor_network_name     = "sensor-nsi-vpc"
subnetwork_mgmt_name    = "sensor-nsi-mgmt-subnet"
subnetwork_mgmt_cidr    = "10.0.1.0/24"
subnetwork_mon_name     = "sensor-nsi-mon-subnet"
subnetwork_mon_cidr     = "10.0.2.0/24"
subnetwork_mon_gateway  = "10.0.2.1"
instance_ssh_key_pub    = "~/.ssh/id_rsa.pub"
image                   = "projects/corelight-image-dist-prod/global/images/corelight-sensor-v28-3-3-us"
license_key_file_path   = "/Users/jacobfiola/work/enrichment-deploy/license.txt"
community_string        = "corelight!"

# Fleet configuration (optional)
fleet_url            = ""
fleet_token          = ""
fleet_server_sslname = ""

# NSI Configuration - IMPORTANT!
organization_id = "536691410123"  # Numeric org ID (e.g., "123456789012")

# VPCs to mirror (leave empty for now, we'll add these in Phase 3)
mirrored_vpcs = []