Hi team! We need help creating two organization-level NSI resources for our Corelight sensor deployment. These are one-time resources that we'll reference (but not manage) in our Terraform code.

**Prerequisites:**
You'll need `roles/networksecurity.admin` at org level (536691410123), or these permissions:
- `networksecurity.securityProfiles.create`
- `networksecurity.securityProfileGroups.create`

**Commands to run:**

```bash
# Step 1: Create Security Profile
gcloud network-security security-profiles custom-mirroring create corelight-mirror-profile \
  --organization=536691410123 \
  --location=global \
  --description="Corelight sensor mirroring profile - managed by Cloud team" \
  --mirroring-endpoint-group="projects/cloud-408817/locations/global/mirroringEndpointGroups/corelight-nsi-endpoint-group"

# Step 2: Create Security Profile Group
gcloud network-security security-profile-groups create corelight-mirror-profile-group \
  --organization=536691410123 \
  --location=global \
  --description="Corelight sensor mirroring profile group - managed by Cloud team" \
  --custom-mirroring-profile="organizations/536691410123/locations/global/securityProfiles/corelight-mirror-profile"
```

**After running, please send us the full resource IDs:**

```bash
# Get Security Profile ID
gcloud network-security security-profiles custom-mirroring describe corelight-mirror-profile \
  --organization=536691410123 \
  --location=global \
  --format="value(name)"

# Get Security Profile Group ID
gcloud network-security security-profile-groups describe corelight-mirror-profile-group \
  --organization=536691410123 \
  --location=global \
  --format="value(name)"
```

Expected output format:
```
organizations/536691410123/locations/global/securityProfiles/corelight-mirror-profile
organizations/536691410123/locations/global/securityProfileGroups/corelight-mirror-profile-group
```

**Important:** Please don't delete these resources - our sensors will reference them. Let us know if you hit any errors!

Thanks!
