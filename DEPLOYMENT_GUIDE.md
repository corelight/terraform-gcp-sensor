# NSI Out-of-Band Mirroring Deployment Guide

## Overview

This module uses **GCP Network Security Integration (NSI) Out-of-Band Mirroring**, which requires organization-level security profiles.

If you don't have organization-level permissions, this deployment follows a **three-phase process** where your organization's security/IT team creates the org-level resources, and you manage everything else via Terraform.

---

## Architecture Summary

**What gets created where:**

| Resource | Created By | Permissions Level | Phase |
|----------|-----------|-------------------|-------|
| Mirroring Deployment Group | Terraform | Project-level | Phase 1 |
| Mirroring Deployment | Terraform | Project-level | Phase 1 |
| Mirroring Endpoint Group | Terraform | Project-level | Phase 1 |
| **Security Profile** | **Org Admin** | **Org-level** | **Phase 2** |
| **Security Profile Group** | **Org Admin** | **Org-level** | **Phase 2** |
| Firewall Policies | Terraform | Project-level | Phase 3 |
| Firewall Rules | Terraform | Project-level | Phase 3 |
| Endpoint Associations | Terraform | Project-level | Phase 3 |

---

## Prerequisites

### If You Have Org-Level Permissions

If you have `roles/networksecurity.admin` at your organization level, you can skip this guide and deploy everything at once. The Terraform module will create all resources including security profiles.

### If You DON'T Have Org-Level Permissions

Follow this three-phase process:
1. You deploy the endpoint infrastructure (Phase 1)
2. Your org admin creates security profiles (Phase 2)
3. You complete the deployment (Phase 3)

**You'll need:**
- An organization admin with `roles/networksecurity.admin` or equivalent
- The `IT_TEAM_COMMANDS.md` file from this repo to share with your org admin

---

## Phase 1: Deploy Endpoint Infrastructure

**Goal:** Create the mirroring endpoint group that will receive traffic, and get its ID for your org admin.

### Step 1.1: Temporarily Disable Firewall Resources

Since security profiles don't exist yet, temporarily comment out the firewall policy resources.

**Edit `mirroring_rules.tf`** and add `#` at the beginning of lines 22-91 (the firewall policy resource blocks):

```bash
# Quick way with sed:
sed -i.bak '22,91s/^/# /' mirroring_rules.tf
```

Or manually comment out these blocks:
- `google_compute_network_firewall_policy.mirror_policies`
- `google_compute_network_firewall_policy_rule.mirror_ingress`
- `google_compute_network_firewall_policy_rule.mirror_egress`
- `google_compute_network_firewall_policy_association.mirror_associations`

### Step 1.2: Configure Variables

Create a `terraform.tfvars` file with your configuration:

```hcl
# Required variables
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

# Fleet configuration (optional)
fleet_url            = "https://your-fleet.example.com"
fleet_token          = "your-fleet-token"
fleet_server_sslname = "your-fleet-ssl-name"

# NSI Configuration - IMPORTANT!
organization_id = "YOUR-ORG-ID-HERE"  # Numeric org ID (e.g., "123456789012")

# VPCs to mirror (leave empty for now, we'll add these in Phase 3)
mirrored_vpcs = []
```

**How to find your organization ID:**
```bash
gcloud organizations list
# Look for the numeric ID (not the domain name)
```

### Step 1.3: Deploy Phase 1 Resources

```bash
terraform init
terraform plan
terraform apply
```

**What gets created:**
- Internal Load Balancer (mirroring collector)
- Mirroring Deployment Group
- Mirroring Deployment
- Mirroring Endpoint Group
- Sensor managed instance group
- Health checks, backend services, etc.

### Step 1.4: Get Endpoint Group ID

After successful apply:

```bash
terraform output mirroring_endpoint_group_id
```

**Expected output:**
```
projects/your-project/locations/global/mirroringEndpointGroups/corelight-mirroring-endpoint-group
```

**Save this ID!** You'll provide it to your org admin.

### Step 1.5: Contact Your Organization Admin

Send your org admin:
1. The endpoint group ID from above
2. The file `IT_TEAM_COMMANDS.md`
3. Your desired security profile names (defaults: `corelight-mirror-profile` and `corelight-mirror-profile-group`)

**Email template:**

```
Subject: Request: Create NSI Security Profiles for Corelight Sensor Deployment

Hi [Org Admin],

I'm deploying Corelight sensors with NSI out-of-band mirroring and need your help creating
the organization-level security profiles (requires roles/networksecurity.admin).

Mirroring Endpoint Group ID:
projects/YOUR-PROJECT/locations/global/mirroringEndpointGroups/corelight-mirroring-endpoint-group

Organization ID:
YOUR-ORG-ID

Please follow the instructions in the attached IT_TEAM_COMMANDS.md file to create:
1. Security Profile: corelight-mirror-profile
2. Security Profile Group: corelight-mirror-profile-group

Once created, please send me the full resource IDs so I can complete the deployment.

Thank you!

Attachment: IT_TEAM_COMMANDS.md
```

---

## Phase 2: Org Admin Creates Security Profiles

**This phase is performed by your organization admin** (someone with org-level permissions).

Your org admin will follow `IT_TEAM_COMMANDS.md` to:
1. Create the security profile (references your endpoint group from Phase 1)
2. Create the security profile group (contains the security profile)
3. Send you back the full resource IDs

### What You're Waiting For

Your org admin will provide two resource IDs:

```
Security Profile ID:
organizations/YOUR-ORG-ID/locations/global/securityProfiles/corelight-mirror-profile

Security Profile Group ID:
organizations/YOUR-ORG-ID/locations/global/securityProfileGroups/corelight-mirror-profile-group
```

**Once you receive these, proceed to Phase 3.**

---

## Phase 3: Complete the Deployment

**Goal:** Enable firewall policies and finish deploying the mirroring infrastructure.

### Step 3.1: Verify Configuration

Check that your `terraform.tfvars` has the correct values:

```hcl
# Must match what org admin created
organization_id              = "YOUR-ORG-ID"
mirroring_profile_name       = "corelight-mirror-profile"
mirroring_profile_group_name = "corelight-mirror-profile-group"

# Now specify which VPCs to mirror
mirrored_vpcs = [
  {
    network    = "vpc-to-monitor-1"
    project_id = "project-id-1"  # Optional if same as main project
  },
  {
    network    = "vpc-to-monitor-2"
    project_id = "project-id-2"
  }
]
```

### Step 3.2: Uncomment Firewall Resources

Restore the firewall policy resources from Phase 1:

```bash
# If you used sed, restore from backup:
cp mirroring_rules.tf.bak mirroring_rules.tf

# Or manually remove the # from lines 22-91
```

### Step 3.3: Plan and Apply

```bash
terraform plan
```

**Review carefully - you should see:**
- ✅ Data sources reading the org-level security profiles
- ✅ New firewall policies being created
- ✅ New firewall rules being created
- ✅ New endpoint associations being created (one per VPC)

**You should NOT see:**
- ❌ Destruction of existing endpoint group or ILB
- ❌ Creation of security profiles (those are managed externally)

If the plan looks correct:

```bash
terraform apply
```

### Step 3.4: Verify Deployment

```bash
# Check all outputs
terraform output

# Verify data sources resolved
terraform show | grep -A5 "data.google_network_security_security_profile"

# List firewall policies
gcloud compute network-firewall-policies list --project=YOUR-PROJECT
```

**Expected outputs:**
- `mirroring_deployment_group_id`
- `mirroring_deployment_id`
- `mirroring_endpoint_group_id`
- `vpc_association_ids` (map of VPC name → association ID)

---

## Verification

### Check Traffic Flow

1. **Firewall policies attached to VPCs:**
   ```bash
   gcloud compute networks describe VPC-NAME \
     --project=YOUR-PROJECT \
     --format="value(firewallPolicy)"
   ```

2. **Mirroring rules active:**
   ```bash
   gcloud compute network-firewall-policies describe POLICY-NAME \
     --project=YOUR-PROJECT \
     --global \
     --format="value(rules)"
   ```

3. **Sensor receiving traffic:**
   - SSH to a sensor instance
   - Check for incoming Geneve-encapsulated packets
   - Verify Corelight logs show traffic from expected VPCs

### Test Multi-VPC Identification

If you're mirroring from multiple VPCs, verify the sensor can identify which VPC traffic originated from:
- Geneve headers should include VPC network ID
- Corelight logs should tag traffic with source VPC

---

## Troubleshooting

### Error: "Security profile not found"

```
Error: Error reading SecurityProfile: ... not found
```

**Causes:**
- Org admin hasn't completed Phase 2 yet
- Resource names don't match (`mirroring_profile_name` variable)
- Wrong organization ID

**Solution:**
- Confirm org admin created the profiles
- Verify `organization_id` matches your org
- Check `mirroring_profile_name` matches what was created

### Error: "Permission denied" on endpoint association

```
Error creating MirroringEndpointGroupAssociation: ... PERMISSION_DENIED
```

**Causes:**
- Terraform doesn't have permissions in the target VPC's project
- VPC doesn't exist

**Solution:**
- Verify VPC names and project IDs in `mirrored_vpcs`
- Grant Terraform service account permissions in customer projects
- Required permissions: `compute.networks.updatePolicy`, `networksecurity.mirroringEndpointGroupAssociations.create`

### Error: "Invalid security profile group reference"

```
Error: security_profile_group not found
```

**Causes:**
- Org admin created the profile but not the profile group
- Profile group name mismatch

**Solution:**
- Verify org admin created BOTH resources (profile AND group)
- Check `mirroring_profile_group_name` variable

---

## Managing the Deployment

### Adding More VPCs

Simply update `mirrored_vpcs` and apply - no need to involve org admin:

```hcl
mirrored_vpcs = [
  { network = "existing-vpc-1" },
  { network = "existing-vpc-2" },
  { network = "new-vpc-3" }  # ← Add new VPCs here
]
```

```bash
terraform apply
```

### Changing Mirroring Rules

Update firewall rule variables in `terraform.tfvars`:

```hcl
# Mirror specific IP ranges instead of all traffic
mirroring_src_ip_ranges  = ["10.0.0.0/8", "172.16.0.0/12"]
mirroring_dest_ip_ranges = ["0.0.0.0/0"]
```

```bash
terraform apply
```

### Updating Security Profiles

**You cannot update security profiles directly** - they're managed by your org admin.

To make changes:
1. Contact your org admin
2. Request changes to the security profile
3. Or request `roles/networksecurity.admin` at org level so you can manage them yourself

---

## Rollback

### Rollback Phase 3 Only

```bash
terraform destroy \
  -target=google_compute_network_firewall_policy.mirror_policies \
  -target=google_network_security_mirroring_endpoint_group_association.vpc_associations
```

### Complete Rollback

```bash
# Destroy all Terraform resources
terraform destroy
```

Your org admin will need to delete the security profiles:
```bash
gcloud network-security security-profile-groups delete corelight-mirror-profile-group \
  --organization=YOUR-ORG-ID \
  --location=global

gcloud network-security security-profiles delete corelight-mirror-profile \
  --organization=YOUR-ORG-ID \
  --location=global
```

---

## Alternative: Get Org-Level Permissions

To avoid the three-phase process in the future, request your organization grant you:

**Option 1: Full role**
```bash
gcloud organizations add-iam-policy-binding YOUR-ORG-ID \
  --member="user:YOUR-EMAIL" \
  --role="roles/networksecurity.admin"
```

**Option 2: Custom role (minimal permissions)**
```bash
# Create custom role
gcloud iam roles create CorelightNSIOperator \
  --organization=YOUR-ORG-ID \
  --permissions="networksecurity.securityProfiles.create,networksecurity.securityProfiles.use,networksecurity.securityProfileGroups.create,networksecurity.securityProfileGroups.use"

# Grant to yourself
gcloud organizations add-iam-policy-binding YOUR-ORG-ID \
  --member="user:YOUR-EMAIL" \
  --role="organizations/YOUR-ORG-ID/roles/CorelightNSIOperator"
```

With org-level permissions, you can deploy everything in one step without the three-phase process.

---

## Summary

| Phase | Who | What | Time |
|-------|-----|------|------|
| **1** | You | Deploy endpoint infrastructure, get endpoint group ID | 10-15 min |
| **2** | Org Admin | Create security profiles using your endpoint ID | 5 min |
| **3** | You | Complete deployment with firewall policies | 10 min |

**Total time:** ~30 minutes (most time is coordination between phases)

**One-time setup:** After Phase 2, you can add/remove VPCs and modify mirroring rules without involving your org admin.

---

## Support

For issues with:
- **Terraform module**: Check GitHub issues or contact Corelight support
- **Org-level permissions**: Contact your organization's GCP administrator
- **NSI features**: Refer to [GCP NSI Documentation](https://cloud.google.com/network-security/docs/network-security-integration)
