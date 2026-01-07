# NSI Out-of-Band Mirroring vs Traditional Packet Mirroring

## Executive Summary

**Network Security Integration (NSI) Out-of-Band Mirroring** is NOT a newer version of traditional GCP Packet Mirroring - it's a completely different architecture for traffic inspection. Both solutions mirror traffic to inspection appliances, but they use different resource types, have different capabilities, and serve different use cases.

**For our use case (multiple customer VPCs funneling to centralized sensors), NSI Out-of-Band is the correct choice.**

## Current Implementation: Traditional Packet Mirroring

### What We're Using Now
- **Resource Type**: `google_compute_packet_mirroring`
- **Scope**: Single VPC network-based mirroring
- **Configuration**: Simple tag-based filtering
- **Location**: load_balancer.tf:61-82

### How It Works
```hcl
google_compute_packet_mirroring.traffic_mirror
├── Mirrors traffic from resources tagged with "traffic-source"
├── Sends to Internal Load Balancer (is_mirroring_collector = true)
├── Filter by direction (BOTH), IP protocols, CIDR ranges
└── Scoped to single VPC network
```

### Characteristics
- **Simple Setup**: Single resource configuration
- **Tag-Based Filtering**: Mirrors resources with specific network tags
- **VPC-Scoped**: Operates within one VPC network
- **Basic Filtering**: Direction, IP protocols, CIDR ranges
- **Standard Packet Format**: Original packet format preserved

### **Current Limitation**: One-to-One VPC-to-Sensor Mapping
- Each `google_compute_packet_mirroring` resource can only mirror ONE VPC
- To mirror multiple customer VPCs, you'd need:
  - Multiple packet mirroring resources (one per VPC)
  - Multiple sensor deployments (one per VPC) OR
  - Complex routing/networking to funnel multiple mirrors to one sensor
- **Not scalable for multi-tenant/multi-VPC customer scenarios**

## NSI Out-of-Band Integration: The Solution for Multi-VPC Monitoring

### What NSI Provides
- **Resource Types**: Multiple new NSI-specific resources
- **Scope**: Cross-project, multi-VPC, organization-wide deployments
- **Configuration**: Global network firewall policies with security profiles
- **Architecture**: Producer-consumer model with endpoint groups

### How It Works
```
NSI Out-of-Band Architecture (Multi-VPC to Single Sensor):
┌─────────────────────────────────────────────────────────────┐
│ Producer Side (Single Centralized Sensor Deployment)        │
│ ├── Mirroring Deployment Group (regional)                   │
│ ├── Mirroring Deployment (zonal, linked to ILB)            │
│ └── Internal Load Balancer → Corelight Sensors             │
└─────────────────────────────────────────────────────────────┘
                         ▲
                         │ (Geneve encapsulation with VPC metadata)
                         │
        ┌────────────────┼────────────────┐
        │                │                │
┌───────▼──────┐  ┌──────▼─────┐  ┌──────▼─────┐
│ Customer VPC │  │Customer VPC│  │Customer VPC│
│      #1      │  │     #2     │  │     #3     │
└──────────────┘  └────────────┘  └────────────┘
       │                 │                │
       └─────────────────┴────────────────┘
                         │
┌────────────────────────▼─────────────────────────────────────┐
│ Consumer Side (Multiple VPC Associations)                    │
│ ├── Mirroring Endpoint Group (global, reusable)             │
│ ├── Endpoint Association #1 → Customer VPC #1               │
│ ├── Endpoint Association #2 → Customer VPC #2               │
│ ├── Endpoint Association #3 → Customer VPC #3               │
│ └── Network Firewall Policies (per VPC, define what to mirror)│
└──────────────────────────────────────────────────────────────┘
```

### Key Technical Differences

| Feature | Traditional Packet Mirroring | NSI Out-of-Band |
|---------|------------------------------|-----------------|
| **Resource Model** | Single `google_compute_packet_mirroring` | Multiple NSI resources (deployment groups, endpoints, associations) |
| **VPCs per Sensor** | **1:1 (One VPC only)** | **Many:1 (Multiple VPCs to one sensor)** ✓ |
| **Encapsulation** | Original packet format | **Geneve encapsulation** with VPC metadata |
| **VPC Identification** | Not preserved | **VPC network ID in Geneve header** ✓ |
| **Filtering Mechanism** | Network tags on resources | **Global network firewall policies** with layer 4 matching |
| **Scope** | Single VPC network | **Cross-project, multi-VPC, organization-wide** ✓ |
| **Session Handling** | Per-packet evaluation | **Session-based mirroring** (entire flow) |
| **Management Model** | Decentralized per-VPC | **Centralized producer-consumer** model ✓ |
| **Rule Actions** | Binary (mirror or not) | `MIRROR`, `DO_NOT_MIRROR`, `GOTO_NEXT` |
| **Security Integration** | Standalone | Integrates with **security profiles and profile groups** |
| **Policy Enforcement** | Tag-based | Secure tags + firewall policy rules |
| **Multi-Tenant Support** | Poor (can't identify source VPC) | **Excellent (Geneve metadata identifies source)** ✓ |

## Why We Should Migrate: Customer Requirements

### Customer Use Case
**Multiple Customer VPCs → Single Centralized Corelight Sensor Deployment**

Customers want:
1. Monitor traffic from **multiple VPCs** (multi-tenant, or different environments)
2. Send all mirrored traffic to a **single centralized sensor deployment**
3. **Identify which VPC** the traffic originated from for analysis and compliance
4. Simplify operations with **centralized management**

### Why Traditional Packet Mirroring Fails This Use Case

**Problem**: `google_compute_packet_mirroring` is scoped to a single VPC network.

To mirror 3 customer VPCs with traditional packet mirroring:
```
Option 1: Deploy 3 separate sensor instances (expensive, complex)
VPC #1 → Packet Mirroring → Sensor #1
VPC #2 → Packet Mirroring → Sensor #2
VPC #3 → Packet Mirroring → Sensor #3

Option 2: Complex routing (loses VPC identity)
VPC #1 → Packet Mirroring → Router/Proxy → Sensor
VPC #2 → Packet Mirroring → Router/Proxy → Sensor
VPC #3 → Packet Mirroring → Router/Proxy → Sensor
Problem: Sensor can't tell which VPC traffic came from!
```

### Why NSI Out-of-Band Solves This

**Solution**: One producer deployment, multiple consumer associations

```
Sensor Deployment (Producer)
├── Mirroring Deployment Group
├── Mirroring Deployment → ILB → Corelight Sensors
│
Multiple Customer VPCs (Consumers)
├── VPC #1 → Endpoint Association #1 ──┐
├── VPC #2 → Endpoint Association #2 ──┼→ Same Producer Deployment
└── VPC #3 → Endpoint Association #3 ──┘
```

**Benefits**:
1. **Single sensor deployment** handles all VPCs (cost-effective)
2. **Geneve encapsulation** includes VPC network ID in packet metadata
3. Corelight sensor can **identify source VPC** for each flow
4. **Centralized policy management** across all customer VPCs
5. **Scalable**: Add new customer VPCs by creating new endpoint associations

## Recommendation: Migrate to NSI Out-of-Band

### Decision: **MIGRATE TO NSI OUT-OF-BAND**

**Primary Reason**: Customer requirement for multiple VPCs funneling to a single sensor deployment.

### Benefits for Our Use Case

1. **Multi-VPC Support** ✓
   - Current: One VPC per sensor deployment
   - With NSI: Unlimited VPCs per sensor deployment via endpoint associations

2. **VPC Identification** ✓
   - Current: No way to identify source VPC in mirrored packets
   - With NSI: Geneve header includes VPC network identifier

3. **Centralized Management** ✓
   - Current: Manage packet mirroring resources per VPC
   - With NSI: Single producer deployment, add consumers as needed

4. **Cost Efficiency** ✓
   - Current: Potentially multiple sensor deployments
   - With NSI: Single sensor deployment serves all customers

5. **Operational Simplicity** ✓
   - Current: Manage N separate packet mirroring configurations
   - With NSI: One producer + N lightweight endpoint associations

### What We Need to Verify

1. **Geneve Encapsulation Support**
   - **ACTION REQUIRED**: Confirm Corelight sensors support Geneve-encapsulated packets
   - Geneve adds ~8 bytes overhead + VPC metadata
   - Corelight must be able to decapsulate and extract VPC ID

2. **Sensor Configuration**
   - May need to configure Corelight to expect Geneve format
   - Verify logging/analysis includes VPC source identification

3. **MTU Considerations**
   - Geneve encapsulation increases packet size
   - Ensure network MTU accommodates overhead

## Architecture Changes Required

### Old Architecture (Traditional Packet Mirroring)
```
Module deploys:
├── ILB (is_mirroring_collector=true)
├── Backend service → Sensor MIG
└── Packet mirroring (single VPC)
```

### New Architecture (NSI Out-of-Band)
```
Module deploys:
Producer Side (in sensor project):
├── ILB (is_mirroring_collector=true)
├── Backend service → Sensor MIG
├── Mirroring Deployment Group (regional)
└── Mirroring Deployment (zonal, references ILB)

Consumer Side (per customer VPC):
├── Mirroring Endpoint Group (global, can be reused)
├── Endpoint Group Association (links VPC to producer)
├── Network Firewall Policy (defines mirror rules)
└── Policy Association (attaches policy to VPC)
```

### Module Design: Support Multiple VPCs

The terraform module should be updated to:
1. **Create producer resources once** (deployment group, deployment)
2. **Accept list of VPC networks** as input
3. **Create consumer resources per VPC** (endpoint associations)
4. **Optionally manage firewall policies** per VPC or shared

Example variable structure:
```hcl
variable "mirrored_vpcs" {
  type = list(object({
    network_name                = string
    firewall_policy_name        = string
    mirroring_rule_config       = object({
      src_ip_ranges  = list(string)
      dest_ip_ranges = list(string)
      layer4_configs = list(object({
        protocol = string
        ports    = list(string)
      }))
    })
  }))
  description = "List of VPC networks to mirror to the sensor"
}
```

## Migration Steps

1. **Verify Geneve Support with Corelight**
   - Contact Corelight support
   - Confirm sensor version compatibility
   - Document configuration requirements

2. **Update Terraform Module**
   - Replace `google_compute_packet_mirroring` with NSI resources
   - Add support for multiple VPC associations
   - Update variables and outputs

3. **Test in Non-Production**
   - Deploy with single VPC first
   - Verify traffic capture and VPC identification
   - Add second VPC, validate multi-VPC scenario

4. **Migrate Production**
   - Deploy NSI resources alongside existing packet mirroring
   - Validate sensor receives traffic from both
   - Cut over by removing old packet mirroring
   - Monitor metrics during transition

5. **Document for Customers**
   - Update deployment guides
   - Explain Geneve encapsulation
   - Provide VPC identification examples

## Critical Action Items

- [ ] **Contact Corelight**: Confirm Geneve encapsulation support
- [ ] **Update Module**: Implement NSI resources with multi-VPC support
- [ ] **Test Geneve**: Verify sensor can decapsulate and identify VPC
- [ ] **Update Documentation**: Migration guide for existing deployments
- [ ] **Customer Communication**: Notify about architecture change benefits

## Documentation References

- **NSI Out-of-Band Overview**: https://cloud.google.com/network-security-integration/docs/out-of-band/out-of-band-integration-overview
- **Traditional Packet Mirroring**: https://cloud.google.com/vpc/docs/packet-mirroring
- **Geneve Encapsulation**: https://datatracker.ietf.org/doc/html/rfc8926
- **Current Implementation**: `/Users/jacobfiola/work/terraform-gcp-sensor/load_balancer.tf:61-82`
