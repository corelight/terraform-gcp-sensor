locals {
  region                  = "us-west1"
  zone                    = "us-west1-a"
  project_id              = "<project-id>"
  auth                    = "~/.config/gcloud/application_default_credentials.json"
  instance_ssh_key_pub    = "~/.ssh/id_ed25519_cl.pub"
  instance_bastion_image  = "ubuntu-os-cloud/ubuntu-2004-lts"
  instance_sensor_image   = "alma-8-20240506203234"
  subnetwork_mgmt_cidr    = "10.129.0.0/24"
  subnetwork_mon_cidr     = "10.3.0.0/24"
  subnetwork_mon_gateway  = "10.3.0.1"
  sensor_license          = "~/corelight-license.txt"
  sensor_community_string = "managedPassword!"
}

####################################################################################################
# Configure the provider
####################################################################################################

provider "google" {
  project     = local.project_id
  credentials = file(local.auth)
  region      = local.region
  zone        = local.zone
}

####################################################################################################
# Create a VPC
####################################################################################################

module "custom_vpc" {
  region               = local.region
  subnetwork_mgmt_cidr = local.subnetwork_mgmt_cidr
  subnetwork_mon_cidr  = local.subnetwork_mon_cidr

  source = "../../modules/network"
}

####################################################################################################
# Create a Bastion
####################################################################################################

module "custom_bastion" {
  zone                 = local.zone
  network_mgmt_name    = module.custom_vpc.network_mgmt_name
  subnetwork_mgmt_name = module.custom_vpc.subnetwork_mgmt_name
  instance_ssh_key_pub = local.instance_ssh_key_pub
  image                = local.instance_bastion_image

  source = "../../modules/bastion"
}

####################################################################################################
# Create Sensor Managed Instance Group
####################################################################################################

module "custom_sensor" {
  region                  = local.region
  zone                    = local.zone
  network_mgmt_name       = module.custom_vpc.network_mgmt_name
  subnetwork_mgmt_name    = module.custom_vpc.subnetwork_mgmt_name
  network_prod_name       = module.custom_vpc.network_prod_name
  subnetwork_mon_name     = module.custom_vpc.subnetwork_mon_name
  subnetwork_mgmt_cidr    = local.subnetwork_mgmt_cidr
  subnetwork_mon_cidr     = local.subnetwork_mon_cidr
  subnetwork_mon_gateway  = local.subnetwork_mon_gateway
  instance_ssh_key_pub    = local.instance_ssh_key_pub
  image                   = local.instance_sensor_image
  sensor_license          = file(local.sensor_license)
  sensor_community_string = local.sensor_community_string

  source = "../../modules/sensor"
}
