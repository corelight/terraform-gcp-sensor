# Commands for IT Team - Create Org-Level NSI Resources

## Overview

This document contains the **exact commands** the IT team needs to run to create the organization-level NSI resources that will unblock the Corelight Cloud team's development.

These resources will be created **once** by IT and then **referenced** (not managed) by our Terraform code.

## Important: Two-Phase Process

Because the security profile needs to reference our mirroring endpoint group (which Terraform creates), this is a **two-phase process**:

1. **Phase 1**: Cloud team runs Terraform to create the endpoint group
2. **Phase 2**: IT team runs commands below using the endpoint group ID
3. **Phase 3**: Cloud team updates Terraform to reference the org-level resources

**IT team: Wait for the Cloud team to provide you with the ENDPOINT_GROUP_ID before running these commands!**

---

## Prerequisites

The person running these commands needs:
- `roles/networksecurity.admin` at organization level, OR
- A custom role with these permissions:
  - `networksecurity.securityProfiles.create`
  - `networksecurity.securityProfileGroups.create`

---

## Important Notes Before Running Commands

1. **Wait for endpoint group ID** - Cloud team will provide this first
2. **These resources are permanent** - They should NOT be deleted unless we explicitly ask
3. **Resource names matter** - Use the exact names specified below (we'll reference them in Terraform)
4. **Order matters** - Create the Security Profile before the Security Profile Group
5. **One-time operation** - You only need to run these commands once

---

## Step 1: Set the Endpoint Group ID Variable

**Important:** Replace `<ENDPOINT_GROUP_ID>` with the ID provided by the Cloud team.

The ID will look like:
```
projects/YOUR-PROJECT/locations/global/mirroringEndpointGroups/corelight-mirroring-endpoint-group
```

**Command:**

```bash
# Set this variable (replace with actual ID from Cloud team)
ENDPOINT_GROUP_ID="<ENDPOINT_GROUP_ID_PROVIDED_BY_CLOUD_TEAM>"

# Verify it's set correctly
echo $ENDPOINT_GROUP_ID
```

---

## Step 2: Create the Security Profile

**What this does:** Creates the mirroring profile that points to our endpoint group

**Command:**

```bash
gcloud network-security security-profiles custom-mirroring create corelight-mirror-profile \
  --organization=536691410123 \
  --location=global \
  --description="Corelight sensor mirroring profile - managed by Cloud team" \
  --mirroring-endpoint-group="${ENDPOINT_GROUP_ID}"
```

**Expected Output:**
```
Create request issued for: [corelight-mirror-profile]
Waiting for operation [organizations/536691410123/locations/global/operations/operation-xxxxx] to complete...done.
Created security profile [corelight-mirror-profile].
```

**If you get an error:** Send us the full error message and we'll help troubleshoot.

---

## Step 3: Create the Security Profile Group

**What this does:** Creates a container that holds the security profile

**Command:**

```bash
gcloud network-security security-profile-groups create corelight-mirror-profile-group \
  --organization=536691410123 \
  --location=global \
  --description="Corelight sensor mirroring profile group - managed by Cloud team" \
  --custom-mirroring-profile="organizations/536691410123/locations/global/securityProfiles/corelight-mirror-profile"
```

**Expected Output:**
```
Create request issued for: [corelight-mirror-profile-group]
Waiting for operation [organizations/536691410123/locations/global/operations/operation-xxxxx] to complete...done.
Created security profile group [corelight-mirror-profile-group].
```

---

## Step 4: Verify Resources Were Created

**Command:**

```bash
# List security profiles
gcloud network-security security-profiles list \
  --organization=536691410123 \
  --location=global \
  --filter="name:corelight-mirror-profile"

# List security profile groups
gcloud network-security security-profile-groups list \
  --organization=536691410123 \
  --location=global \
  --filter="name:corelight-mirror-profile-group"
```

**Expected Output:**
You should see both resources listed with their full IDs.

---

## Step 5: Get the Full Resource IDs (Important!)

We need the **full resource IDs** to reference these in Terraform.

**Command:**

```bash
# Get Security Profile ID
gcloud network-security security-profiles describe corelight-mirror-profile \
  --organization=536691410123 \
  --location=global \
  --format="value(name)"

# Get Security Profile Group ID
gcloud network-security security-profile-groups describe corelight-mirror-profile-group \
  --organization=536691410123 \
  --location=global \
  --format="value(name)"
```

**Copy the output of both commands and send them to us!**

Expected format:
```
organizations/536691410123/locations/global/securityProfiles/corelight-mirror-profile
organizations/536691410123/locations/global/securityProfileGroups/corelight-mirror-profile-group
```

---

## Alternative: Run as a Single Script

If you prefer, here's a single script that runs all commands:

```bash
#!/bin/bash
set -e

# ====================================================================
# IMPORTANT: Set this variable first!
# The Cloud team will provide you with the endpoint group ID
# ====================================================================
ENDPOINT_GROUP_ID="<REPLACE_WITH_ENDPOINT_GROUP_ID_FROM_CLOUD_TEAM>"

# Verify endpoint group ID is set
if [[ "$ENDPOINT_GROUP_ID" == "<REPLACE_WITH_ENDPOINT_GROUP_ID_FROM_CLOUD_TEAM>" ]]; then
  echo "❌ ERROR: You must set the ENDPOINT_GROUP_ID variable first!"
  echo "Please replace the placeholder with the actual ID provided by the Cloud team."
  exit 1
fi

ORG_ID="536691410123"
PROFILE_NAME="corelight-mirror-profile"
GROUP_NAME="corelight-mirror-profile-group"

echo "Using endpoint group: ${ENDPOINT_GROUP_ID}"
echo ""

echo "Creating Security Profile..."
gcloud network-security security-profiles custom-mirroring create ${PROFILE_NAME} \
  --organization=${ORG_ID} \
  --location=global \
  --description="Corelight sensor mirroring profile - managed by Cloud team" \
  --mirroring-endpoint-group="${ENDPOINT_GROUP_ID}"

echo ""
echo "Creating Security Profile Group..."
gcloud network-security security-profile-groups create ${GROUP_NAME} \
  --organization=${ORG_ID} \
  --location=global \
  --description="Corelight sensor mirroring profile group - managed by Cloud team" \
  --custom-mirroring-profile="organizations/${ORG_ID}/locations/global/securityProfiles/${PROFILE_NAME}"

echo ""
echo "Verifying resources..."
echo ""
echo "Security Profile:"
gcloud network-security security-profiles describe ${PROFILE_NAME} \
  --organization=${ORG_ID} \
  --location=global \
  --format="value(name)"

echo ""
echo "Security Profile Group:"
gcloud network-security security-profile-groups describe ${GROUP_NAME} \
  --organization=${ORG_ID} \
  --location=global \
  --format="value(name)"

echo ""
echo "✅ All resources created successfully!"
echo ""
echo "Please send the above resource IDs to the Corelight Cloud team."
```

**To use:**
1. Save to a file: `create-nsi-resources.sh`
2. **Edit the file and replace `<REPLACE_WITH_ENDPOINT_GROUP_ID_FROM_CLOUD_TEAM>` with the actual ID**
3. Make executable: `chmod +x create-nsi-resources.sh`
4. Run: `./create-nsi-resources.sh`

---

## What Happens Next?

**Complete Three-Phase Process:**

1. **Phase 1 (Cloud Team)**: Deploy Terraform to create endpoint group, get its ID
2. **Phase 2 (IT Team)**: Run commands above using the endpoint group ID ← **YOU ARE HERE**
3. **Phase 3 (Cloud Team)**: Update Terraform to reference your org-level resources and complete deployment

After you run these commands and send us the resource IDs, we'll be fully unblocked!

---

## Troubleshooting

### Error: "PERMISSION_DENIED"

**Problem:** The user doesn't have org-level permissions

**Solution:** Grant `roles/networksecurity.admin` at organization level:
```bash
gcloud organizations add-iam-policy-binding 536691410123 \
  --member="user:<YOUR-EMAIL>" \
  --role="roles/networksecurity.admin"
```

### Error: "Resource already exists"

**Problem:** The resources were already created

**Solution:** Just get the resource IDs using Step 4 commands

### Error: "Invalid organization ID"

**Problem:** Organization ID is incorrect

**Solution:** Verify organization ID:
```bash
gcloud organizations list
```

### Error: "API not enabled"

**Problem:** Network Security API not enabled for the organization

**Solution:** Enable it:
```bash
gcloud services enable networksecurity.googleapis.com \
  --project=<your-project-id>
```

---

## Important: Do NOT Delete These Resources

Once created, these resources should remain in place. Our Terraform will reference them but not manage them.

**If you need to delete them for any reason, please contact the Cloud team first** - deleting them will break our sensor deployments.

---

## Questions?

Contact the Corelight Cloud team:
- Jacob Fiola (jacob.fiola@corelight.com)
- Ryan Haney (ryan.haney@corelight.com)
- Sean Demura (sean.demura@corelight.com)
- Hassan Baker (hassan.baker@corelight.com)
