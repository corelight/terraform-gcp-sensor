# NSI Out-of-Band Mirroring - Network Firewall Policies
#
# Creates global network firewall policies with mirroring rules for each VPC
# specified in the mirrored_vpcs variable. These policies reference the
# organization-level security profile group created by your IT team.
#
# Requires: google-beta provider >= 7.15.0
# Documentation: https://cloud.google.com/network-security-integration/docs/nsi-overview

locals {
  # Full resource ID for org-level security profile group (created by IT team)
  security_profile_group_id = var.security_profile_group_id != "" ? var.security_profile_group_id : (
    var.organization_id != "" ?
    "organizations/${var.organization_id}/locations/global/securityProfileGroups/${var.mirroring_profile_group_name}" :
    ""
  )
}

# Create global network firewall policy for each mirrored VPC
resource "google_compute_network_firewall_policy" "mirror_policies" {
  for_each = local.vpcs_map

  name        = "${each.value.network_name}-mirror-policy"
  project     = each.value.project_id
  description = "Global network firewall policy with mirroring rules for ${each.value.network_name}"
}

# Create ingress mirroring rule
resource "google_compute_network_firewall_policy_packet_mirroring_rule" "mirror_ingress" {
  provider = google-beta
  for_each = local.vpcs_map

  action                 = "mirror"
  description            = "Mirror ingress traffic to Corelight sensor"
  direction              = "INGRESS"
  firewall_policy        = google_compute_network_firewall_policy.mirror_policies[each.key].name
  priority               = 10
  rule_name              = "mirror-ingress-all"
  project                = each.value.project_id
  security_profile_group = local.security_profile_group_id

  match {
    src_ip_ranges = var.mirroring_src_ip_ranges
    layer4_configs {
      ip_protocol = "all"
    }
  }
}

# Create egress mirroring rule
resource "google_compute_network_firewall_policy_packet_mirroring_rule" "mirror_egress" {
  provider = google-beta
  for_each = local.vpcs_map

  action                 = "mirror"
  description            = "Mirror egress traffic to Corelight sensor"
  direction              = "EGRESS"
  firewall_policy        = google_compute_network_firewall_policy.mirror_policies[each.key].name
  priority               = 11
  rule_name              = "mirror-egress-all"
  project                = each.value.project_id
  security_profile_group = local.security_profile_group_id

  match {
    dest_ip_ranges = var.mirroring_dest_ip_ranges
    layer4_configs {
      ip_protocol = "all"
    }
  }
}

# Associate the firewall policy with each VPC
resource "google_compute_network_firewall_policy_association" "mirror_associations" {
  for_each = local.vpcs_map

  name              = "${each.value.network_name}-mirror-association"
  attachment_target = each.value.network
  firewall_policy   = google_compute_network_firewall_policy.mirror_policies[each.key].name
  project           = each.value.project_id
}
