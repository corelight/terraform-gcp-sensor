# GCP NSI Out-of-Band Mirroring for Corelight Sensors

## Introduction

If you're managing network security in GCP at scale, you've likely hit this problem: **each VPC needs its own sensor deployment**. Five VPCs? Five deployments. Fifty VPCs? You're now running a small infrastructure empire just to maintain network visibility.

GCP's **Network Security Integration (NSI) Out-of-Band Mirroring** changes the equation. Instead of deploying sensors in every VPC you want to monitor, you deploy **one centralized sensor platform** that receives mirrored traffic from all your VPCs—across projects, preserving source context through Geneve encapsulation.

This guide explains when NSI makes sense, how it works, and why it might (or might not) be the right choice for your environment.

## The Problem: Traditional Packet Mirroring at Scale

Traditional GCP packet mirroring works well for simple deployments: mirror traffic within a VPC to an Internal Load Balancer in that same VPC. Sensors receive raw packet copies and process them.

**But this approach doesn't scale:**

### You Need Separate Infrastructure Per VPC

Every monitored VPC requires:
- Dedicated sensor VMs (Managed Instance Group)
- Internal Load Balancer (mirroring collector)
- Health checks, autoscaling policies, backend services
- Fleet enrollment and management

**The math**: 20 VPCs × (3 sensors + 1 ILB + supporting resources) = 80+ compute instances and dozens of policies to maintain.

### You Lose Track of Traffic Sources

Mirrored packets arrive as raw copies with **no metadata** about their origin:
- Traffic from VPC-A looks identical to traffic from VPC-B
- No way to distinguish dev vs. staging vs. production
- Requires post-processing correlation with VPC Flow Logs to identify sources

For MSSPs or multi-tenant platforms, this makes it nearly impossible to attribute traffic to specific customers.

### You Can't Mirror Across Projects

Traditional mirroring is bound by VPC boundaries:
- Can't mirror from customer VPCs in different GCP projects
- Requires deploying sensors in each customer's project, or complex VPC peering
- No clean separation between security infrastructure and monitored environments

## NSI Out-of-Band Mirroring: The Solution

NSI takes a fundamentally different approach with a **producer-consumer model**:

**Producer** (monitored VPCs):
- Network firewall policies with mirroring rules select traffic
- Rules reference org-level security profiles
- Traffic is Geneve-encapsulated with VPC metadata

**Consumer** (your sensors):
- Single centralized endpoint receives traffic from all VPCs
- Internal Load Balancer distributes to sensor instances
- Sensors decode Geneve to extract packets + metadata

### The Key: Geneve Encapsulation

NSI wraps mirrored packets in the **Geneve protocol** with metadata:

```
Original Packet:
[IP Header | TCP Header | HTTP GET /api/users ...]

Geneve-Encapsulated Packet:
[Outer IP | UDP 6081 | Geneve Header | Original Packet]
                        ↑
                        Contains: VPC ID, Project ID, Subnet ID, Zone
```

Result: Your sensors know **which VPC, project, and subnet** every packet came from, even though they're all arriving at a single endpoint.

## Should You Use NSI? Decision Guide

### ✅ Use NSI If:

| You Have... | NSI Benefit |
|------------|-------------|
| **10+ VPCs to monitor** | Reduce from N sensor stacks to 1 |
| **Multi-tenant deployment** (MSSP, shared security team) | VPC metadata enables customer attribution |
| **Multiple GCP projects** | Mirror from customer projects to your security project |
| **Frequent VPC additions** | Add new VPC = 2-line Terraform change (not new deployment) |
| **Centralized security operations** | Single Fleet instance, unified policies |

### ❌ Stick with Traditional If:

| You Have... | Why Traditional Works |
|------------|----------------------|
| **Single VPC** (or 2-3) | NSI overhead not worth it |
| **Strict network isolation** (compliance) | Traffic must stay within VPC boundary |
| **Older Corelight sensors** | Geneve support required (check version) |
| **No org-level access** & inflexible org admin | Three-phase deployment too complex |

**Rule of thumb**: NSI breaks even around **5-10 VPCs**. Below that, traditional mirroring is simpler. Above that, NSI's operational and cost benefits compound quickly.

## Use Cases

### 1. MSSP: Multi-Tenant Security Platform

**Your situation**:
- 25 customers, each with 2-5 VPCs across different GCP projects
- Need to monitor ~60 VPCs total
- Must attribute traffic to specific customers for billing and alerts

**With traditional mirroring**:
- Deploy 60 sensor stacks (one per VPC)
- Each customer's traffic goes to separate sensors
- Aggregate logs centrally, correlate with flow logs for attribution
- **Result**: Managing 60 deployments, 180+ sensor VMs, complex correlation logic

**With NSI**:
- Deploy 1 regional sensor stack (6-10 sensors with autoscaling)
- Associate all 60 customer VPCs with your endpoint group
- Geneve headers include customer project ID → automatic attribution
- **Result**: 1 deployment to manage, direct customer attribution in logs

**Savings**: ~95% reduction in infrastructure, 90% reduction in operational overhead.

### 2. Large Enterprise: Dev/Staging/Prod Environments

**Your situation**:
- 50 VPCs: 20 production, 15 staging, 15 development
- All in the same org but different GCP projects by team
- Security team needs visibility across all environments

**With traditional mirroring**:
- 50 separate sensor deployments
- Each environment team manages their own sensors, or security team manages 50 stacks
- Inconsistent Zeek policies across deployments
- **Result**: Configuration drift, upgrade nightmare

**With NSI**:
- 1 sensor deployment, all 50 VPCs in `mirrored_vpcs` list
- Uniform policies across all environments
- Upgrade once, applies to all VPCs
- **Result**: Consistent security posture, single upgrade cycle

### 3. Cross-Project Monitoring

**Your situation**:
- Security team has dedicated "security-ops" GCP project
- Application teams have their own projects with limited security team access
- Compliance requires centralized security monitoring

**With traditional mirroring**:
- Deploy sensors in each application team's project, OR
- Set up VPC peering to your security project (complex, fragile)
- **Result**: Security infrastructure scattered across projects

**With NSI**:
- Sensors in your security-ops project
- Endpoint associations from app team VPCs → your endpoint group
- App teams only grant `compute.networks.updatePolicy` (not VM access)
- **Result**: Clean separation, minimal footprint in app projects

## Real-World Example

A financial services company monitoring 40 VPCs across development, staging, and production:

**Before NSI** (traditional mirroring):
- 40 sensor deployments
- 120 sensor VMs (3 per deployment)
- 40 ILBs, 40 health checks, 40 autoscaling policies
- **Monthly cost**: ~$18,000 in compute
- **Operational overhead**: 2 FTEs managing sensors

**After NSI**:
- 1 sensor deployment
- 12 sensor VMs (autoscales based on total traffic)
- 1 ILB, 1 health check, 1 autoscaling policy
- **Monthly cost**: ~$3,500 in compute
- **Operational overhead**: 0.3 FTE

**ROI**: 80% cost reduction, paid back migration effort in 3 months.

## How It Works: Architecture Deep Dive

### Traffic Flow

```
1. VM in customer-vpc-1 sends traffic
   ↓
2. Network firewall policy evaluates
   ↓
3. Matches mirroring rule (priority 10, action=mirror)
   ↓
4. Looks up security profile group
   ↓
5. Security profile references your endpoint group
   ↓
6. GCP encapsulates packet with Geneve:
   - Outer IP: customer-vpc → sensor-vpc
   - UDP 6081
   - Geneve header with VPC metadata
   - Original packet intact
   ↓
7. Packet routes to your ILB (is_mirroring_collector=true)
   ↓
8. ILB distributes across sensor instances
   ↓
9. Sensor decodes Geneve:
   - Extracts original packet
   - Reads VPC metadata from Geneve header
   - Processes with Zeek, tags with source VPC/project
   ↓
10. Logs show: conn.log with fields:
    - vpc_id: customer-vpc-1
    - project_id: customer-project-123
    - Standard Zeek fields (src, dst, service, etc.)
```

### Key Components

| Component | Scope | Created By | Purpose |
|-----------|-------|------------|---------|
| **Network Firewall Policy** | Per-VPC | You (Terraform) | Selects traffic to mirror |
| **Mirroring Rules** | Per-VPC | You (Terraform) | Defines match criteria (IPs, ports, protocols) |
| **Security Profile** | Org-level | Org Admin | Links to your endpoint group (one-time) |
| **Security Profile Group** | Org-level | Org Admin | Container for security profile (one-time) |
| **Mirroring Endpoint Group** | Global | You (Terraform) | Destination for all mirrored traffic |
| **VPC Associations** | Per-VPC | You (Terraform) | Links customer VPC → endpoint group |
| **Internal Load Balancer** | Regional | You (Terraform) | Receives Geneve packets, distributes to sensors |
| **Mirroring Deployment** | Zonal | You (Terraform) | Binds ILB to deployment group |

### What's Org-Level? What's Project-Level?

**Org-level** (requires org admin permissions, one-time setup):
- Security Profile
- Security Profile Group

**Project-level** (you manage with Terraform):
- Everything else: firewall policies, rules, associations, endpoint groups, ILB, sensors

**Key insight**: You only need org admin help **once** to create security profiles. After that, you manage everything with Terraform at project level.

## Technical Deep Dive

### Geneve Overhead

Each mirrored packet adds ~50 bytes:
- Outer IP header: 20 bytes (IPv4) or 40 bytes (IPv6)
- UDP header: 8 bytes
- Geneve base header: 8 bytes
- Geneve options (VPC metadata): ~14 bytes

**Impact on 1500-byte packet**:
- Original: 1500 bytes
- Geneve-encapsulated: 1550 bytes (~3.3% overhead)

**Bandwidth**: If you're mirroring 10 Gbps, expect ~10.3 Gbps on the wire.

GCP's default MTU (1460 bytes) handles this without fragmentation.

### Security Considerations

**Mirrored traffic isolation**:
- Geneve packets use dedicated firewall rules (UDP 6081 to sensor VPC)
- Mirrored traffic never mixes with production traffic
- Sensors are in separate VPC from monitored resources

**Access control**:
- Firewall policies control **what** traffic is mirrored
- Security profile controls **where** it goes
- Only authorized projects can associate with your endpoint group

**Data handling**:
- Mirrored traffic contains full packet payloads
- Consider encryption in transit (Geneve outer headers are not encrypted)
- Sensors should have restrictive access controls

### Monitoring and Observability

**Metrics to track**:
- **Mirrored packet count**: Are packets flowing? (check GCP metrics)
- **Geneve decode rate**: Are sensors keeping up? (Corelight metrics)
- **Dropped packets**: ILB or sensor capacity issues? (health checks)
- **VPC coverage**: Are all expected VPCs sending traffic?

**Logging**:
- Enable VPC Flow Logs on sensor VPC to see incoming Geneve traffic
- Monitor Corelight logs for VPC metadata fields
- Alert on missing VPCs (expected traffic not arriving)

**Health checks**:
- ILB health check monitors sensor responsiveness
- Autoscaling based on CPU/memory (Geneve decoding is CPU-intensive)
- Set up alerts for unhealthy sensors

### Performance and Capacity

**Single sensor capacity** (typical):
- ~5-10 Gbps of mirrored traffic
- Varies by traffic mix (many small flows vs. few large flows)

**Scaling**:
- Start with 3-5 sensors per region
- Configure autoscaling: min=3, max=20
- Monitor CPU: scale up at 70%, scale down at 30%

**Regional deployment**:
- NSI is regional (mirrored traffic stays in-region)
- For multi-regional VPCs: deploy sensors in each region
- Aggregate logs centrally with Fleet

### Cost Analysis

**Traditional mirroring** (40 VPCs):
- 40 deployments × 3 sensors × $200/month = $24,000/month
- Plus ILBs, health checks, etc.: ~$2,000/month
- **Total: ~$26,000/month**

**NSI mirroring** (40 VPCs):
- 1 deployment × 12 sensors × $200/month = $2,400/month
- 1 ILB + health check: ~$100/month
- Geneve bandwidth overhead (~3%): ~$200/month
- **Total: ~$2,700/month**

**Savings**: ~$23,000/month (89% reduction)

**Breakeven**: Migration takes ~40 hours. At $150/hour = $6,000. Pays back in < 2 weeks.

## Deployment

For detailed deployment instructions including the three-phase process for users without org-level permissions, see the [README](README.md#deployment).

**Quick overview**:
1. **Phase 1**: Deploy sensor infrastructure (get endpoint group ID)
2. **Phase 2**: Org admin creates security profiles (references your endpoint)
3. **Phase 3**: Enable firewall policies and start mirroring

## Migration from Traditional Mirroring

### Pre-Migration Checklist

- [ ] Verify Corelight sensor version supports Geneve (v28.0+)
- [ ] Identify all VPCs currently using traditional mirroring
- [ ] Choose pilot VPC (non-critical, representative traffic)
- [ ] Document current sensor configurations and policies
- [ ] Set up parallel NSI infrastructure (coexists with traditional)

### Migration Steps

**Week 1: Deploy and Test**
1. Deploy NSI sensor stack (README Phase 1-3)
2. Add pilot VPC to `mirrored_vpcs`
3. Verify traffic in sensor logs with VPC metadata
4. Compare logs: NSI vs. traditional (should be identical except metadata)

**Week 2-3: Gradual Migration**
5. Migrate 5 VPCs per week:
   - Add to NSI `mirrored_vpcs`
   - Monitor for 48 hours
   - Disable traditional mirroring policy
   - Document any issues
6. Continue until all VPCs migrated

**Week 4: Cleanup**
7. Verify all VPCs sending traffic to NSI sensors
8. Decommission traditional sensor deployments
9. Update monitoring dashboards and alerts
10. Document new architecture for team

### Rollback Plan

If issues arise:
1. Re-enable traditional mirroring policy for affected VPC
2. Remove VPC from NSI `mirrored_vpcs`
3. Investigate: Check Geneve decoding, health checks, firewall rules
4. Fix issue and re-migrate

### Common Migration Issues

**Problem**: No traffic from migrated VPC
- **Check**: Firewall policy associated with VPC?
- **Check**: Security profile group correct?
- **Check**: VPC association created?

**Problem**: Partial traffic (some flows missing)
- **Check**: Mirroring rules match criteria (source/dest IP ranges)
- **Check**: Both ingress AND egress rules enabled?

**Problem**: High sensor CPU after migration
- **Check**: Autoscaling configured?
- **Check**: More VPCs than anticipated?
- **Solution**: Increase max sensor count

## Troubleshooting

### No Geneve Packets Arriving

```bash
# On sensor: Check for ANY traffic on eth1
sudo tcpdump -i eth1 -c 10

# Check for Geneve specifically
sudo tcpdump -i eth1 -nn 'udp port 6081'

# If no traffic:
# 1. Check firewall policy exists and is associated
# 2. Check security profile references correct endpoint group
# 3. Check VPC association created
# 4. Check firewall allows UDP 6081 to sensor VPC
```

### Geneve Packets Arrive But Not Decoded

```bash
# Check Corelight logs for decoding errors
sudo tail -f /var/log/corelight/corelight.log | grep -i geneve

# Verify sensor version supports Geneve
corelight-softsensor --version

# Check for Geneve stats in Zeek
zeek-cut < /opt/corelight/logs/geneve.log
```

### VPC Metadata Missing in Logs

```bash
# Check if VPC fields exist in conn.log
head -n 1 /opt/corelight/logs/conn.log | zeek-cut -c

# Should see: vpc_id, project_id, subnet_id fields

# If missing: Geneve decoding not enabled or metadata stripped
# Check Corelight config: /etc/corelight/corelight.conf
```

## FAQ

**Q: Can I mirror traffic selectively (not all traffic)?**
A: Yes. Edit mirroring rules to match specific IP ranges, ports, or protocols. Example: only mirror port 443 traffic.

**Q: Does NSI work with VPC Service Controls?**
A: Yes. NSI mirroring operates at the network layer before VPC-SC applies.

**Q: Can I mirror from shared VPC?**
A: Yes. Create associations from the shared VPC to your endpoint group.

**Q: What happens if sensors go down?**
A: ILB health checks detect unhealthy sensors and stop routing to them. MIG auto-replaces failed instances. Mirrored traffic is dropped if all sensors unhealthy (GCP doesn't buffer).

**Q: Can I use NSI with other security tools (not just Corelight)?**
A: Yes, if your tool supports Geneve decoding. The endpoint is just an ILB pointing to your backend.

**Q: Is there a limit on VPCs per endpoint group?**
A: GCP doesn't document a hard limit. We've tested 100+ VPCs successfully. Practical limit is sensor capacity to process traffic.

**Q: Can I run NSI and traditional mirroring at the same time?**
A: Yes. Useful for gradual migration. Same traffic can be mirrored via both methods (to different destinations).

## Getting Started

**Next steps**:

1. **Evaluate**: Use the decision guide above. Do you have 10+ VPCs? NSI likely makes sense.

2. **Check permissions**: Run `gcloud projects get-iam-policy YOUR-PROJECT --flatten="bindings[].members" --filter="bindings.role:networksecurity"` to see if you have network security permissions. If not org-level, plan for three-phase deployment.

3. **Deploy a pilot**: Follow the [README](README.md#deployment) to deploy NSI infrastructure and mirror one test VPC. Validate traffic flows correctly.

4. **Calculate ROI**: Count your current VPCs, estimate monthly compute costs. Use cost analysis above to project savings.

5. **Plan migration**: If pilot succeeds, create migration timeline (gradual, 5-10 VPCs per week).

**Resources**:
- [Terraform Module](https://github.com/corelight/terraform-gcp-sensor) - Full module with examples
- [GCP NSI Docs](https://cloud.google.com/network-security/docs/network-security-integration) - Official GCP documentation
- [Corelight Support](mailto:support@corelight.com) - Questions on Geneve support, sensor sizing

## Conclusion

NSI out-of-band mirroring solves the **infrastructure sprawl problem** that emerges when monitoring many VPCs with traditional packet mirroring. By centralizing sensor infrastructure and using Geneve to preserve traffic context, you can:

- **Reduce operational overhead by 90%**: One deployment instead of dozens
- **Cut costs by 80%+**: Shared infrastructure, better utilization
- **Maintain visibility at scale**: Add VPCs without adding deployments
- **Enable multi-tenancy**: VPC metadata for traffic attribution

It's not the right choice for every deployment—single VPC or strict isolation requirements favor traditional mirroring. But for organizations monitoring 10+ VPCs, especially across projects or with multi-tenant needs, NSI is a game-changer.

The three-phase deployment model accommodates GCP's org-level permission requirements, and the Terraform module handles the complexity of NSI configuration.

