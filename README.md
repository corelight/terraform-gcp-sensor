# terraform-gcp-sensor

<img src="docs/overview.png" alt="overview">

Terraform module for deploying Corelight Cloud Sensors on GCP with **NSI (Network Security Integration) Out-of-Band Mirroring** support.

## Features

- **Multi-VPC Traffic Mirroring**: Mirror traffic from multiple customer VPCs to a single centralized sensor deployment
- **NSI Out-of-Band Integration**: Uses GCP's Network Security Integration for scalable packet mirroring
- **Geneve Encapsulation**: Preserves VPC metadata in mirrored packets for multi-tenant identification
- **Autoscaling**: Managed Instance Groups with health checks and autoscaling
- **Fleet Integration**: Supports Corelight Fleet for centralized sensor management

## Architecture

This module deploys:
- **Producer Side**: Corelight sensors with Internal Load Balancer and NSI mirroring deployment
- **Consumer Side**: Per-VPC endpoint associations and network firewall policies for traffic mirroring

### Single VPC Deployment

```terraform
provider "google" {
  project        = "<the default project to manage resources in>"
  credentials    = "<path to or the contents of a service account key file>"
  region         = "<the default region to manage resources in>"
  zone           = "<the default zone to manage resources in>"
  default_labels = {
    terraform : true,
    example : true,
    purpose : "Corelight"
  }
}

module "sensor" {
  source = "github.com/corelight/terraform-gcp-sensor"

  project_id              = "<gcp project id>"
  region                  = "<instance region>"
  zone                    = "<instance availability zone>"
  sensor_network_name     = "<VPC network where sensors are deployed>"
  subnetwork_mgmt_name    = "<management subnetwork name>"
  subnetwork_mgmt_cidr    = "<management subnetwork CIDR>"
  subnetwork_mon_name     = "<monitoring subnetwork name>"
  subnetwork_mon_cidr     = "<monitoring subnetwork CIDR>"
  subnetwork_mon_gateway  = "<monitoring subnetwork gateway>"
  instance_ssh_key_pub    = "<instance ssh public key>"
  image                   = "<Corelight sensor image>"
  license_key_file_path   = "path/to/license-key.txt"
  community_string        = "<the community string (api string) often times referenced by Fleet>"

  fleet_token          = "<the pairing token from the Fleet UI>"
  fleet_url            = "<the URL of the fleet instance from the Fleet UI>"
  fleet_server_sslname = "<the ssl name provided by Fleet>"

  # NSI Mirroring Configuration (defaults to mirroring sensor_network_name)
  mirrored_vpcs = []  # Empty = mirror sensor_network_name
}
```

### Multi-VPC Deployment

For mirroring traffic from multiple customer VPCs to a single sensor deployment:

```terraform
module "sensor" {
  source = "github.com/corelight/terraform-gcp-sensor"

  project_id              = "<gcp project id>"
  region                  = "<instance region>"
  zone                    = "<instance availability zone>"
  sensor_network_name     = "<VPC network where sensors are deployed>"
  subnetwork_mgmt_name    = "<management subnetwork name>"
  subnetwork_mgmt_cidr    = "<management subnetwork CIDR>"
  subnetwork_mon_name     = "<monitoring subnetwork name>"
  subnetwork_mon_cidr     = "<monitoring subnetwork CIDR>"
  subnetwork_mon_gateway  = "<monitoring subnetwork gateway>"
  instance_ssh_key_pub    = "<instance ssh public key>"
  image                   = "<Corelight sensor image>"
  license_key_file_path   = "path/to/license-key.txt"
  community_string        = "<api string>"

  fleet_token          = "<fleet pairing token>"
  fleet_url            = "<fleet URL>"
  fleet_server_sslname = "<fleet ssl name>"

  # NSI Mirroring: Monitor multiple customer VPCs
  mirrored_vpcs = [
    {
      network    = "projects/customer-project-1/global/networks/prod-vpc"
      project_id = "customer-project-1"
    },
    {
      network    = "projects/customer-project-2/global/networks/prod-vpc"
      project_id = "customer-project-2"
    },
    {
      network = "local-vpc-name"  # Uses module's project_id by default
    }
  ]

  mirroring_labels = {
    terraform = "true"
    environment = "production"
  }
}
```

## NSI Out-of-Band Mirroring

This module uses **GCP Network Security Integration (NSI) Out-of-Band Mirroring** instead of traditional packet mirroring. This architecture enables:

1. **Centralized Sensor Deployment**: Single sensor deployment monitors multiple VPCs
2. **VPC Identification**: Geneve encapsulation preserves source VPC metadata
3. **Scalability**: Add new customer VPCs without deploying additional sensors
4. **Session-Based Filtering**: Mirror complete flows rather than individual packets

### Key Differences from Traditional Packet Mirroring

| Feature | NSI Out-of-Band | Traditional Packet Mirroring |
|---------|-----------------|------------------------------|
| VPCs per Sensor | **Many:1** | 1:1 |
| Encapsulation | Geneve with VPC metadata | Original packets |
| Scope | Multi-project, multi-VPC | Single VPC |
| Management | Centralized deployment groups | Per-VPC resources |

For detailed deployment instructions, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).

## Requirements

- Corelight sensor must support **Geneve encapsulation** for NSI out-of-band mirroring
- IAM roles: `networksecurity.mirroringAdmin` and `networksecurity.mirroringEndpointNetworkAdmin`
- Network MTU must accommodate Geneve overhead (~8 bytes)

## Variables

### Required Variables

- `project_id`: GCP project ID for sensor deployment
- `region`: GCP region
- `zone`: GCP zone for zonal resources
- `sensor_network_name`: VPC network name to create for sensors
- `subnetwork_mgmt_name`: Management subnetwork name to create (for eth0 - SSH, management)
- `subnetwork_mgmt_cidr`: Management subnetwork CIDR (e.g., "10.0.1.0/24")
- `subnetwork_mon_name`: Monitoring subnetwork name to create (for eth1 - mirrored traffic)
- `subnetwork_mon_cidr`: Monitoring subnetwork CIDR (e.g., "10.0.2.0/24")
- `subnetwork_mon_gateway`: Monitoring subnetwork gateway (e.g., "10.0.2.1")

**Note:** Sensors use two network interfaces - both will be created in the same VPC network (`sensor_network_name`) on different subnets. The Terraform module creates the VPC and both subnets.
- `instance_ssh_key_pub`: SSH public key path
- `image`: Corelight sensor image
- `license_key_file_path`: Path to file containing Corelight license key (or use fleet_url)
- `community_string`: API/community string

### NSI Mirroring Variables

- `mirrored_vpcs`: List of VPCs to mirror from (defaults to sensor_network_name if empty)
  - `network`: VPC network name or self_link
  - `project_id`: (Optional) Project ID if VPC is in different project
- `mirroring_deployment_group_id`: Deployment group ID (default: "corelight-mirroring-deployment-group")
- `mirroring_deployment_id`: Deployment ID (default: "corelight-mirroring-deployment")
- `mirroring_endpoint_group_id`: Endpoint group ID (default: "corelight-mirroring-endpoint-group")
- `mirroring_labels`: Labels for NSI resources (default: {})

### Optional: Avoiding Resource Name Conflicts

All resource names have default values starting with `corelight-`. If you have multiple deployments or need to avoid conflicts with existing resources, you can customize these names:

```hcl
region_health_check_resource_name                = "my-deployment-health-check"
firewall_resource_name                           = "my-deployment-firewall-rule"
instance_template_group_manager_resource_name    = "my-deployment-mig"
region_autoscaler_resource_name                  = "my-deployment-autoscaler"
region_backend_service_resource_name             = "my-deployment-backend"
forwarding_rule_resource_name                    = "my-deployment-forwarding-rule"
mirroring_deployment_group_id                    = "my-deployment-group"
mirroring_deployment_id                          = "my-deployment"
mirroring_endpoint_group_id                      = "my-endpoint-group"

# Network names
sensor_network_name                              = "my-monitoring-vpc"
subnetwork_mgmt_name                             = "my-mgmt-subnet"
subnetwork_mon_name                              = "my-mon-subnet"
```

See `variables.tf` for all customizable resource names.

### Deployment

The variables for this module all have default values that can be overwritten
to meet your naming and compliance standards.

Deployment examples can be found [here][].

[here]: https://github.com/corelight/corelight-cloud/tree/main/terraform/gcp-mig-sensor

## License

The project is licensed under the [MIT][] license.

[MIT]: LICENSE
