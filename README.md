# ⚠️ DEPRECATED — This repository has moved

> **This repository is no longer maintained and has been archived (read-only).**
> All Corelight Terraform modules now live in the
> **[Corelight Terraform monorepo](https://github.com/corelight/terraform)**.

**New location:** [`modules/gcp/sensor`](https://github.com/corelight/terraform/tree/main/modules/gcp/sensor)

**Update your module `source`** (replace `<version>` with a [release tag](https://github.com/corelight/terraform/releases), e.g. `v29.0.5-5`):

```terraform
module "sensor" {
  source = "github.com/corelight/terraform//modules/gcp/sensor?ref=<version>"
}
```

See the [monorepo README](https://github.com/corelight/terraform#readme) for the full module list.

---

# terraform-gcp-sensor

<img src="docs/overview.png" alt="overview">

Terraform for Corelight's GCP Cloud Sensor Deployment.

### Usage

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
  
  project_id             = "<gcp project id>"
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
  license_key             = "<your Corelight sensor license key>"
  community_string        = "<the community string (api string) often times referenced by Fleet>"
  
  fleet_token = "<the pairing token from the Fleet UI>"
  fleet_url   = "<the URL of the fleet instance from the Fleet UI>"
  fleet_server_sslname = "<the ssl name provided by Fleet>"
```

### Deployment

The variables for this module all have default values that can be overwritten
to meet your naming and compliance standards.

Deployment examples can be found [here][].

[here]: https://github.com/corelight/corelight-cloud/tree/main/terraform/gcp-mig-sensor

## License

The project is licensed under the [MIT][] license.

[MIT]: LICENSE
