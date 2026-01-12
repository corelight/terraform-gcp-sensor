# NSI Out-of-Band Mirroring Deployment Guide

## Overview

This Terraform module deploys Corelight sensors with **GCP Network Security Integration (NSI) Out-of-Band Mirroring**. NSI mirroring requires organization-level security profiles, which may require coordination with your GCP organization administrator if you don't have org-level permissions.

## Prerequisites

- GCP Project with necessary APIs enabled:
  - Compute Engine API
  - Network Security API
- Terraform >= 1.0
- Provider: google >= 6.38.0, google-beta >= 7.15.0
- Corelight sensor license key
- Organization ID (numeric, e.g., "123456789012")

### Required Permissions

**Project-level (minimum):**
- `compute.*` permissions for creating VMs, networks, load balancers
- `networksecurity.mirroringDeploymentGroups.create`
- `networksecurity.mirroringDeployments.create`
- `networksecurity.mirroringEndpointGroups.create`

**Organization-level (for security profiles):**
- `networksecurity.securityProfiles.create`
- `networksecurity.securityProfileGroups.create`

If you don't have org-level permissions, follow the **Three-Phase Deployment** below.

---

## Quick Start (With Org-Level Permissions)

If you have `roles/networksecurity.admin` at the organization level, you can deploy everything in one step.

### 1. Configure Variables

Create `terraform.tfvars`:

```hcl
# Required
project_id              = "your-gcp-project"
region                  = "us-central1"
zone                    = "us-central1-a"
sensor_network_name     = "sensor-vpc"
subnetwork_mgmt_name    = "sensor-mgmt-subnet"
subnetwork_mgmt_cidr    = "10.0.1.0/24"
subnetwork_mon_name     = "sensor-mon-subnet"
subnetwork_mon_cidr     = "10.0.2.0/24"
subnetwork_mon_gateway  = "10.0.2.1"
instance_ssh_key_pub    = "~/.ssh/id_rsa.pub"
image                   = "projects/corelight-public/global/images/corelight-sensor-VERSION"
license_key_file_path   = "path/to/license-key.txt"
community_string        = "your-api-string"

# Fleet configuration (optional, if using Corelight Fleet)
fleet_url               = "https://your-fleet.example.com"
fleet_token             = "your-fleet-token"
fleet_server_sslname    = "your-fleet-ssl-name"

# NSI Configuration
organization_id = "YOUR-ORG-ID"  # Find with: gcloud organizations list

# VPCs to mirror
mirrored_vpcs = [
  {
    network    = "vpc-to-monitor-1"
    project_id = "project-id-1"  # Optional if same as main project
  }
]
```

### 2. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 3. Verify

```bash
# Check outputs
terraform output

# Verify mirroring is active
gcloud compute network-firewall-policies list --project=YOUR-PROJECT
```

---

## Three-Phase Deployment (Without Org-Level Permissions)

If you don't have organization-level permissions, you'll need help from your GCP organization administrator. This process creates the infrastructure first, then org-level profiles, then completes the deployment.

### Phase 1: Deploy Endpoint Infrastructure

**Goal:** Create the mirroring endpoint group and get its ID.

#### 1.1. Temporarily Disable Firewall Resources

Since security profiles don't exist yet, comment out the firewall policy resources in `mirroring_rules.tf`:

```bash
# Comment out firewall policy resources (lines ~19-80)
sed -i.bak '/^resource "google_compute_network_firewall_policy"/,/^}/s/^/# /' mirroring_rules.tf
sed -i.bak '/^resource "google_compute_network_firewall_policy_packet_mirroring_rule"/,/^}/s/^/# /' mirroring_rules.tf
sed -i.bak '/^resource "google_compute_network_firewall_policy_association"/,/^}/s/^/# /' mirroring_rules.tf
```

Or manually add `#` before each resource block.

#### 1.2. Configure Variables

Create `terraform.tfvars` (same as Quick Start, but leave `mirrored_vpcs = []` empty for now).

#### 1.3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

#### 1.4. Get Endpoint Group ID

```bash
terraform output mirroring_endpoint_group_id
```

Expected output:
```
projects/your-project/locations/global/mirroringEndpointGroups/corelight-mirroring-endpoint-group
```

**Save this ID!** You'll provide it to your organization administrator.

---

### Phase 2: Request Org Admin Create Security Profiles

**Goal:** Have your GCP organization administrator create the required security profiles.

#### 2.1. Provide Information to Org Admin

Send your organization administrator:
1. The endpoint group ID from Phase 1
2. Your organization ID (from `gcloud organizations list`)
3. The commands below

#### 2.2. Commands for Organization Administrator

**Set variables (customize as needed):**

```bash
ORG_ID="YOUR-ORG-ID"
ENDPOINT_GROUP_ID="projects/your-project/locations/global/mirroringEndpointGroups/corelight-mirroring-endpoint-group"
PROFILE_NAME="corelight-mirror-profile"
GROUP_NAME="corelight-mirror-profile-group"
```

**Create security profile:**

```bash
gcloud network-security security-profiles custom-mirroring create ${PROFILE_NAME} \
  --organization=${ORG_ID} \
  --location=global \
  --description="Corelight sensor mirroring profile" \
  --mirroring-endpoint-group="${ENDPOINT_GROUP_ID}"
```

**Create security profile group:**

```bash
gcloud network-security security-profile-groups create ${GROUP_NAME} \
  --organization=${ORG_ID} \
  --location=global \
  --description="Corelight sensor mirroring profile group" \
  --custom-mirroring-profile="organizations/${ORG_ID}/locations/global/securityProfiles/${PROFILE_NAME}"
```

**Verify and get IDs:**

```bash
# Get security profile ID
gcloud network-security security-profiles describe ${PROFILE_NAME} \
  --organization=${ORG_ID} \
  --location=global \
  --format="value(name)"

# Get security profile group ID
gcloud network-security security-profile-groups describe ${GROUP_NAME} \
  --organization=${ORG_ID} \
  --location=global \
  --format="value(name)"
```

#### 2.3. Receive Resource IDs

Your administrator should provide these IDs:

```
Security Profile ID:
organizations/YOUR-ORG-ID/locations/global/securityProfiles/corelight-mirror-profile

Security Profile Group ID:
organizations/YOUR-ORG-ID/locations/global/securityProfileGroups/corelight-mirror-profile-group
```

---

### Phase 3: Complete the Deployment

**Goal:** Enable firewall policies and complete the NSI mirroring setup.

#### 3.1. Update Configuration

Update `terraform.tfvars` to include VPCs to mirror:

```hcl
# Verify these match what was created
organization_id              = "YOUR-ORG-ID"
mirroring_profile_name       = "corelight-mirror-profile"
mirroring_profile_group_name = "corelight-mirror-profile-group"

# Add VPCs to mirror
mirrored_vpcs = [
  {
    network    = "vpc-to-monitor-1"
    project_id = "project-id-1"
  },
  {
    network    = "vpc-to-monitor-2"
    project_id = "project-id-2"
  }
]
```

#### 3.2. Restore Firewall Resources

Uncomment the firewall policy resources:

```bash
# If you used sed with backup:
cp mirroring_rules.tf.bak mirroring_rules.tf

# Or manually remove the # characters
```

#### 3.3. Apply

```bash
terraform plan  # Review carefully
terraform apply
```

**Expected changes:**
- ✅ Firewall policies created (one per VPC)
- ✅ Mirroring rules created (ingress + egress per VPC)
- ✅ VPC associations created (one per VPC)

#### 3.4. Verify

```bash
# Check all resources
terraform output

# Verify firewall policies
gcloud compute network-firewall-policies list --project=YOUR-PROJECT --global

# Check mirroring rules
gcloud compute network-firewall-policies describe POLICY-NAME \
  --project=YOUR-PROJECT \
  --global \
  --format="value(rules)"
```

---

## Verification

### Test Traffic Mirroring

1. **SSH to a sensor instance:**
   ```bash
   gcloud compute ssh SENSOR-NAME --project=YOUR-PROJECT --zone=YOUR-ZONE --tunnel-through-iap
   ```

2. **Check for Geneve packets (NSI uses UDP port 6081):**
   ```bash
   sudo tcpdump -i eth1 -nn 'udp port 6081'
   ```

3. **Verify Corelight is processing traffic:**
   - Check Corelight logs for decoded traffic
   - Verify VPC metadata is preserved (if mirroring multiple VPCs)

### Common Issues

**No traffic arriving:**
- Verify firewall policies are associated with VPCs
- Check mirroring rules are active (priority 10, 11)
- Confirm UDP 6081 (Geneve) is allowed to sensor VPC
- Verify security profile group references correct endpoint group

**Permission errors:**
- Ensure Terraform has permissions in all projects with mirrored VPCs
- Required: `compute.networks.updatePolicy`, `networksecurity.*`

---

## Managing the Deployment

### Adding More VPCs

Simply update `mirrored_vpcs` and apply:

```hcl
mirrored_vpcs = [
  { network = "existing-vpc-1" },
  { network = "new-vpc-2" }  # Add new VPCs here
]
```

```bash
terraform apply
```

### Modifying Mirroring Rules

Customize which traffic to mirror:

```hcl
# Mirror specific IP ranges
mirroring_src_ip_ranges  = ["10.0.0.0/8"]
mirroring_dest_ip_ranges = ["0.0.0.0/0"]
```

### Destroying Resources

```bash
# Destroy all Terraform-managed resources
terraform destroy
```

**Note:** Organization-level security profiles are not managed by Terraform. Your org admin must delete them separately if needed:

```bash
gcloud network-security security-profile-groups delete corelight-mirror-profile-group \
  --organization=YOUR-ORG-ID \
  --location=global

gcloud network-security security-profiles delete corelight-mirror-profile \
  --organization=YOUR-ORG-ID \
  --location=global
```

---

## Architecture Reference

### NSI Components

| Component | Scope | Created By | Purpose |
|-----------|-------|------------|---------|
| Mirroring Deployment Group | Global | Terraform | Groups mirroring deployments |
| Mirroring Deployment | Zonal | Terraform | Links ILB to deployment group |
| Mirroring Endpoint Group | Global | Terraform | Consumer endpoint (sensor side) |
| Security Profile | Org-level | Org Admin | References endpoint group |
| Security Profile Group | Org-level | Org Admin | Contains security profiles |
| Firewall Policies | Global | Terraform | Per-VPC mirroring policies |
| Firewall Rules | Global | Terraform | Mirroring rules (ingress/egress) |
| VPC Associations | Global | Terraform | Attaches policies to VPCs |

### Network Flow

```
Source VPC → Firewall Policy (mirror action) →
  Security Profile → Endpoint Group →
  ILB (mirroring collector) →
  Sensor VMs (eth1, UDP 6081)
```

---

## Support

- **Module Issues**: [GitHub Issues](https://github.com/corelight/terraform-gcp-sensor/issues)
- **NSI Documentation**: [GCP Network Security Integration](https://cloud.google.com/network-security/docs/network-security-integration)
- **Corelight Support**: support@corelight.com
