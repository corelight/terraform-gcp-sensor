# NSI Traffic Selection - Security Profile and Mirroring Rules
# This configures which traffic gets mirrored to the sensor

# NOTE: Security profiles and security profile groups are created EXTERNALLY by IT team
# at the organization level. Since Terraform data sources don't exist for these yet,
# we reference them using their full resource IDs provided by IT.
# See IT_TEAM_COMMANDS.md for the commands IT needs to run.

locals {
  # Full resource IDs for org-level security profiles (provided by IT team after Phase 2)
  # Format: organizations/ORG_ID/locations/global/securityProfiles/PROFILE_NAME
  security_profile_id = var.security_profile_id != "" ? var.security_profile_id : (
    var.organization_id != "" ?
    "organizations/${var.organization_id}/locations/global/securityProfiles/${var.mirroring_profile_name}" :
    ""
  )

  # Format: organizations/ORG_ID/locations/global/securityProfileGroups/GROUP_NAME
  security_profile_group_id = var.security_profile_group_id != "" ? var.security_profile_group_id : (
    var.organization_id != "" ?
    "organizations/${var.organization_id}/locations/global/securityProfileGroups/${var.mirroring_profile_group_name}" :
    ""
  )
}

# # 3. Create network firewall policy for each mirrored VPC
# resource "google_compute_network_firewall_policy" "mirror_policies" {
#   for_each = local.vpcs_map
# 
#   name        = "${each.value.network_name}-mirror-policy"
#   project     = each.value.project_id
#   description = "Firewall policy with mirroring rules for ${each.value.network_name}"
# }
# 
# # 4. Create mirroring rule to mirror ingress traffic
# resource "google_compute_network_firewall_policy_rule" "mirror_ingress" {
#   for_each = local.vpcs_map
# 
#   action                 = "mirror"
#   description            = "Mirror ingress traffic to Corelight sensor"
#   direction              = "INGRESS"
#   firewall_policy        = google_compute_network_firewall_policy.mirror_policies[each.key].name
#   priority               = 1000
#   rule_name              = "mirror-ingress-all"
#   project                = each.value.project_id
#   security_profile_group = local.security_profile_group_id
# 
#   match {
#     src_ip_ranges = var.mirroring_src_ip_ranges
#     layer4_configs {
#       ip_protocol = "all"
#     }
#   }
# }
# 
# # 5. Create mirroring rule to mirror egress traffic
# resource "google_compute_network_firewall_policy_rule" "mirror_egress" {
#   for_each = local.vpcs_map
# 
#   action                 = "mirror"
#   description            = "Mirror egress traffic to Corelight sensor"
#   direction              = "EGRESS"
#   firewall_policy        = google_compute_network_firewall_policy.mirror_policies[each.key].name
#   priority               = 1001
#   rule_name              = "mirror-egress-all"
#   project                = each.value.project_id
#   security_profile_group = local.security_profile_group_id
# 
#   match {
#     dest_ip_ranges = var.mirroring_dest_ip_ranges
#     layer4_configs {
#       ip_protocol = "all"
#     }
#   }
# }
# 
# # 6. Associate the firewall policy with each VPC
# resource "google_compute_network_firewall_policy_association" "mirror_associations" {
#   for_each = local.vpcs_map
# 
#   name              = "${each.value.network_name}-mirror-association"
#   attachment_target = each.value.network
#   firewall_policy   = google_compute_network_firewall_policy.mirror_policies[each.key].name
#   project           = each.value.project_id
# }
