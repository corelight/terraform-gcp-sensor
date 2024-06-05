# terraform-gcp-sensor

<img src="docs/overview.png" alt="overview">

Terraform for Corelight's GCP Cloud Sensor Deployment.

### Usage

```hcl
module "sensor" {
  source = "github.com/corelight/terraform-gcp-sensor"

  region                  = "<instance region>"
  zone                    = "<instance availability zone>"
  network_mgmt_name       = "<virtual network management name>"
  subnetwork_mgmt_name    = "<virtual network subnetwork management name>"
  subnetwork_mgmt_cidr    = "<virtual network subnetwork management CIDR>"
  network_prod_name       = "<virtual network name for infra to be monitored"
  subnetwork_mon_name     = "<virtual network subnetwork monitoring name>"
  subnetwork_mon_cidr     = "<virtual network subnetwork monitoring CIDR>"
  subnetwork_mon_gateway  = "<virtual network subnetwork monitoring gateway>"
  instance_ssh_key_pub    = "<instance ssh public key>"
  image                   = "<instance image>"
  sensor_license          = "<your Corelight senosr license key>"
  sensor_community_string = "<the Fleet Manager community string>"
}
```

### Deployment

The variables for this module all have default values that can be overwritten
to meet your naming and compliance standards.

Deployment examples can be found [here](examples).

## License

The project is licensed under the [MIT][] license.

[MIT]: LICENSE
