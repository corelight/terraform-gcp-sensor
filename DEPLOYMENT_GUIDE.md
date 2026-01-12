# Deploying Corelight Sensors with GCP NSI Out-of-Band Mirroring

## Introduction

Network visibility is critical for security operations, but traditional approaches to traffic mirroring often create operational challenges at scale. If you're running Corelight sensors in Google Cloud Platform (GCP), you may have encountered limitations with traditional packet mirroring: the need for separate sensor deployments per VPC, difficulties identifying traffic sources across multiple networks, and the operational overhead of managing dozens of mirroring policies.

GCP's **Network Security Integration (NSI) Out-of-Band Mirroring** addresses these challenges with a fundamentally different architecture. Instead of deploying sensors within each VPC you want to monitor, NSI enables a centralized sensor deployment that can receive mirrored traffic from multiple VPCs—even across different projects.

This guide explores why you might choose NSI out-of-band mirroring over traditional packet mirroring, when it makes sense, and how it works.

## The Challenge: Traditional Packet Mirroring at Scale

Traditional GCP packet mirroring uses a **collector ILB** pattern where mirrored traffic is sent to an Internal Load Balancer within the same VPC being monitored. This works well for simple use cases but introduces challenges as you scale:

### Limitation 1: One Sensor Deployment Per VPC

With traditional mirroring, you deploy sensors in the VPC you want to monitor. The collector ILB and sensors must reside in the same VPC as the mirrored traffic source. This means:

- **100 VPCs = 100 sensor deployments**: Each customer VPC needs its own sensor infrastructure
- **Increased operational complexity**: Managing, upgrading, and monitoring dozens of sensor deployments
- **Higher costs**: Redundant compute, networking, and management overhead across deployments

### Limitation 2: Loss of VPC Context

When you receive traditional mirrored packets, they arrive as raw copies with no metadata about which VPC they originated from. For multi-tenant or multi-environment deployments, this creates problems:

- **No source identification**: Traffic from different VPCs looks identical
- **Complex post-processing**: Requires correlation with flow logs or other sources to determine origin
- **Limited multi-tenancy**: Difficult to mirror multiple customer VPCs to a shared sensor platform

### Limitation 3: VPC Network Boundaries

Traditional mirroring is constrained by VPC boundaries:

- **No cross-project mirroring**: Can't mirror from customer VPCs in different GCP projects
- **Single-project deployments**: Requires co-locating sensors in customer project or complex VPC peering
- **Network topology constraints**: Limited flexibility in deployment architecture

## NSI Out-of-Band Mirroring: A Different Approach

NSI out-of-band mirroring reimagines the architecture with a **producer-consumer model**:

### Producer Side (Monitored VPCs)

The "producer" is any VPC you want to monitor. On the producer side:

- **Firewall policies with mirroring rules** select which traffic to mirror
- **Security profiles** specify where to send mirrored traffic
- **Endpoint associations** link VPCs to the centralized sensor endpoint

### Consumer Side (Corelight Sensors)

The "consumer" is your centralized Corelight sensor deployment. On the consumer side:

- **Mirroring endpoint group** acts as the destination for all mirrored traffic
- **Internal Load Balancer** (marked as mirroring collector) receives Geneve-encapsulated packets
- **Mirroring deployments** link the ILB to the global deployment group
- **Sensors decode Geneve** to extract original packets and VPC metadata

### The Key Innovation: Geneve Encapsulation

NSI uses the **Geneve protocol** (UDP port 6081) to encapsulate mirrored packets with metadata:

```
Original Packet:
[IP Header | TCP Header | Payload]

NSI Mirrored Packet:
[Outer IP | UDP 6081 | Geneve Header (includes VPC ID, project, etc.) | Original Packet]
```

This encapsulation preserves context about where traffic originated, enabling:

- **VPC identification**: Know which VPC every packet came from
- **Multi-tenant support**: Mirror multiple customer VPCs to a single sensor platform
- **Flow tracking**: Maintain session state even when traffic comes from different networks

## Why Choose NSI Out-of-Band Mirroring?

### Use Case 1: Multi-Tenant Security Platforms

**Scenario**: You're a managed security service provider (MSSP) or internal security team supporting multiple business units, each with their own GCP projects and VPCs.

**Traditional approach**: Deploy separate Corelight sensors in each customer's VPC (or project), manage 20+ sensor deployments, aggregate logs centrally.

**NSI approach**: Deploy a single centralized Corelight sensor infrastructure, associate customer VPCs with your endpoint group, mirror traffic from all VPCs to your sensors. VPC metadata in Geneve headers allows you to identify which customer each flow belongs to.

**Benefits**:
- **10x fewer sensor deployments**: One sensor platform instead of one per customer
- **Centralized management**: Single Fleet instance, unified policy, one upgrade cycle
- **Cost efficiency**: Shared compute and networking resources
- **Simplified operations**: One deployment to monitor, secure, and maintain

### Use Case 2: Large Enterprise with Many Environments

**Scenario**: You have 50+ VPCs across development, staging, and production environments in multiple GCP projects.

**Traditional approach**: Deploy 50+ separate sensor stacks, each with its own MIG, autoscaler, health checks, and backends.

**NSI approach**: Deploy one regional sensor stack, add all 50 VPCs to the mirrored_vpcs list, let NSI handle the routing.

**Benefits**:
- **Reduced operational overhead**: Manage one deployment instead of 50
- **Consistent visibility**: Same sensor policies across all environments
- **Easy expansion**: Adding a new VPC is a 2-line Terraform change
- **Better resource utilization**: Sensors scale based on total traffic, not per-VPC capacity planning

### Use Case 3: Cross-Project Monitoring

**Scenario**: You have a centralized security project and need to monitor traffic in customer-owned GCP projects where you have limited access.

**Traditional approach**: Not easily possible without VPC peering and deploying sensors in customer projects.

**NSI approach**: Create endpoint associations from customer VPCs (in their projects) to your endpoint group (in your project). Mirrored traffic flows to your centralized sensors.

**Benefits**:
- **Separation of concerns**: Sensors in your security project, customers manage their own VPCs
- **Minimal customer footprint**: Only firewall policies in customer VPCs, no VMs or complex infrastructure
- **Simplified permissions**: Customers grant network policy permissions, not compute/VM access
- **Clean architecture**: Clear boundary between security infrastructure and monitored environments

### Use Case 4: Simplified Fleet Management

**Scenario**: You want to treat your network monitoring as a platform service, not dozens of individual deployments.

**Traditional approach**: Each VPC has its own sensor instances that need to be enrolled in Fleet, monitored for health, and upgraded independently.

**NSI approach**: Single sensor deployment enrolled in Fleet once. All VPCs share the same sensors, policies, and management plane.

**Benefits**:
- **One Fleet enrollment**: Single pane of glass for all monitored VPCs
- **Consistent policies**: Same Zeek scripts, same detection rules across all environments
- **Faster upgrades**: Upgrade sensors once, not 50 times
- **Unified monitoring**: One set of health checks, one autoscaling configuration

## When Traditional Mirroring Still Makes Sense

NSI out-of-band mirroring isn't always the right choice. Consider traditional packet mirroring when:

### Single VPC Deployments

If you're only monitoring one VPC and don't plan to expand, traditional mirroring is simpler:
- No organization-level security profiles needed
- No Geneve decoding complexity
- Slightly lower latency (no additional encapsulation)

### Strict Network Isolation Requirements

Some compliance frameworks require absolute network isolation:
- Sensors must reside in the monitored VPC
- No traffic can leave the VPC boundary, even as mirrored packets
- Security profiles can't be shared across environments

### No Geneve Support

NSI requires your sensors to decode Geneve encapsulation:
- Older Corelight sensor versions may not support Geneve
- Custom packet processing pipelines might not handle encapsulation
- Check with Corelight support for version requirements

### Cost Sensitivity at Small Scale

For 1-3 VPCs, the cost difference between approaches is minimal:
- NSI has overhead from Geneve encapsulation and security profiles
- Traditional mirroring is straightforward with low operational cost at small scale
- NSI's benefits primarily emerge at scale (10+ VPCs)

## Architecture Overview

Here's how NSI out-of-band mirroring works end-to-end:

### 1. Traffic Selection (Producer VPCs)

Each monitored VPC has a **network firewall policy** with mirroring rules:

```
Firewall Policy: "vpc-prod-mirror-policy"
  └── Rule 1: Mirror ingress traffic (priority 10)
      - Match: All source IPs, all protocols
      - Action: mirror
      - Security Profile Group: organizations/ORG/securityProfileGroups/corelight-mirror
  └── Rule 2: Mirror egress traffic (priority 11)
      - Match: All destination IPs, all protocols
      - Action: mirror
      - Security Profile Group: organizations/ORG/securityProfileGroups/corelight-mirror
```

These rules evaluate traffic before regular firewall rules, allowing you to mirror everything or selectively mirror specific IP ranges, ports, or protocols.

### 2. Security Profiles (Organization Level)

At the GCP organization level, a **security profile** links producer VPCs to the consumer endpoint:

```
Security Profile: "corelight-mirror-profile"
  └── Type: CUSTOM_MIRRORING
  └── Mirroring Endpoint Group: projects/security-project/locations/global/mirroringEndpointGroups/corelight-endpoint

Security Profile Group: "corelight-mirror-profile-group"
  └── Contains: corelight-mirror-profile
```

This is a one-time setup by your GCP organization admin. Once created, you can add as many VPCs as needed without touching the security profiles.

### 3. Mirroring Endpoint Group (Consumer Side)

Your centralized sensor deployment has a **mirroring endpoint group**:

```
Mirroring Endpoint Group: "corelight-endpoint"
  └── Network: projects/security-project/global/networks/sensor-vpc
  └── Associations:
      - VPC: customer-vpc-1 (project: customer-project-1)
      - VPC: customer-vpc-2 (project: customer-project-2)
      - VPC: dev-vpc (project: dev-project)
      - VPC: staging-vpc (project: staging-project)
```

Each VPC association creates a logical link between the producer VPC and your consumer endpoint.

### 4. Internal Load Balancer (Mirroring Collector)

The ILB acts as the receiving endpoint for mirrored traffic:

```
Internal Load Balancer: "corelight-ilb"
  └── is_mirroring_collector: true
  └── Backend: Sensor MIG (us-central1-a, us-central1-b, us-central1-c)
  └── Protocol: UDP
  └── Receives: Geneve-encapsulated packets on UDP 6081
```

The ILB distributes mirrored traffic across your sensor instances using GCP's built-in load balancing algorithms.

### 5. Sensor Processing

Corelight sensors receive Geneve packets and extract:
- **Original packet**: Reconstruct the traffic as it appeared in the source VPC
- **VPC metadata**: Project ID, VPC ID, subnet ID from Geneve headers
- **Flow context**: Use metadata for logging, alerting, and correlation

The result is **full network visibility with multi-VPC awareness**: your Zeek logs include context about which VPC and project every connection originated from.

## Deployment Considerations

NSI requires **security profiles** at the GCP organization level. Most users don't have these permissions and need to coordinate with their organization administrator.

For detailed deployment instructions including the three-phase process for users without org-level permissions, see the [README](README.md#deployment).

## Technical Considerations

### Network MTU

Geneve adds ~50 bytes of overhead:
- **Original packet**: Variable (e.g., 1500 bytes for standard Ethernet)
- **Geneve encapsulation**: ~50 bytes
- **Total**: Original packet size + 50 bytes

Ensure your network can handle the additional overhead. GCP's default MTU (1460 bytes) accommodates this, but if you've customized MTU settings, verify there's headroom for encapsulation.

### Sensor Version Requirements

Verify your Corelight sensor version supports Geneve decoding:
- Check release notes for "NSI support" or "Geneve decoding"
- Test with a pilot VPC before rolling out to production
- Contact Corelight support if unsure about compatibility

### Cross-Project IAM

When mirroring from VPCs in other GCP projects, ensure your Terraform service account has:
- `compute.networks.updatePolicy` in each project with monitored VPCs
- `networksecurity.mirroringEndpointGroupAssociations.create` in your sensor project

This allows Terraform to create endpoint associations linking customer VPCs to your endpoint group.

## Scaling and Performance

### Horizontal Scaling

NSI out-of-band mirroring scales horizontally:

- **Add more sensor instances**: Managed Instance Group autoscales based on traffic
- **ILB distributes load**: GCP automatically balances mirrored traffic across sensors
- **No per-VPC limits**: A single sensor platform can handle hundreds of VPCs

### Regional vs. Multi-Regional

Currently, NSI mirroring deployments are **regional**:
- Deploy sensors in each region where you have VPCs to monitor
- Mirrored traffic stays within the same region
- Global VPCs can mirror from multiple regions to regional sensor deployments

For multi-regional visibility, deploy sensor stacks in each region and aggregate logs centrally using Corelight Fleet.

### Cost Optimization

NSI reduces costs at scale but adds some overhead:

**Savings**:
- **Fewer sensor VMs**: One deployment instead of many
- **Shared infrastructure**: Single ILB, health checks, autoscaling policies
- **Operational efficiency**: Less time managing infrastructure = lower operational cost

**Overhead**:
- **Geneve encapsulation**: ~3-5% bandwidth increase due to additional headers
- **Organization-level resources**: Security profiles and groups (minimal cost)

The breakeven point is typically around **5-10 VPCs**: below this, traditional mirroring is simpler; above this, NSI's efficiency gains compound.

## Migration from Traditional Packet Mirroring

If you're currently using traditional packet mirroring and want to migrate to NSI:

### Step 1: Deploy NSI Infrastructure

Deploy the new NSI-based sensor stack using this Terraform module. This can coexist with your existing traditional mirroring setup.

### Step 2: Pilot VPC

Choose one non-critical VPC to migrate first:
- Add it to `mirrored_vpcs` in your Terraform
- Verify traffic appears in sensor logs with VPC metadata
- Compare traffic volume and flow accuracy with traditional approach

### Step 3: Gradual Migration

Migrate VPCs one at a time:
- Add VPC to NSI mirrored_vpcs
- Verify traffic is mirrored correctly
- Disable traditional packet mirroring policy for that VPC
- Remove old sensor deployment once all VPCs are migrated

### Step 4: Consolidate

Once all VPCs are migrated:
- Decommission old sensor deployments
- Update monitoring and alerting to use the centralized sensor platform
- Document the new architecture for your team

## Getting Started

Ready to try NSI out-of-band mirroring? Here's what you need:

1. **Review the [README](README.md)** for basic module usage and variables
2. **Check your permissions**: Do you have org-level access, or will you need to coordinate with your org admin?
3. **Start with a test VPC**: Deploy sensors and mirror one VPC to validate the setup
4. **Scale gradually**: Add more VPCs once you're comfortable with the architecture

The Terraform module handles the complexity of setting up NSI infrastructure. You focus on defining which VPCs to mirror and configuring your sensor policies.

## Conclusion

NSI out-of-band mirroring represents a shift from **per-VPC sensor deployments** to a **platform approach** for network visibility in GCP. For organizations monitoring multiple VPCs—whether for multi-tenancy, multiple environments, or cross-project visibility—it offers:

- **Operational simplicity**: One sensor deployment instead of many
- **VPC context preservation**: Know where every packet originated
- **Cross-project flexibility**: Monitor VPCs in different GCP projects
- **Cost efficiency**: Shared infrastructure and resources

It's not the right choice for every deployment, but if you're facing the operational overhead of managing dozens of sensor stacks or struggling with VPC identification in a multi-tenant environment, NSI out-of-band mirroring is worth evaluating.

For technical deployment details, see the [README](README.md) and [module documentation](https://github.com/corelight/terraform-gcp-sensor).

---

**Questions?** Contact Corelight support at support@corelight.com or visit our [documentation](https://docs.corelight.com).
