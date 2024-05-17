# terraform-gcp-sensor

<img src="docs/overview.png" alt="overview">

Terraform for Corelight's GCP Cloud Sensor Deployment.

## Getting Started

Corelight Sensors support a broad range of instance types and sizes.
You can create regional MIGs or zonal MIGs. Regional MIGs provide
higher availability compared to zonal MIGs because the instances in
a regional MIG are spread across multiple zones in a single region.

It is important to consider that some cost per GiB of traffic may be
incurred if data is sent between regions within GCP. The sensors operate
independently on individual traffic flows from the internal load balancer -
which means the MIGs can be stateless.

MIG’s can be autoscaled based on several factors, CPU utilization, HTTP
capacity, and select cloud metrics. Here at Corelight, we believe in
using our own products to help secure our own infrastructure. In doing
so, we’ve used our sensors to secure the entirety of our hybrid
deployment, both on premise and in the cloud. For our cloud sensors we
have taken full advantage of autoscaling based on the amount of CPU
utilization to ensure we have enough sensor capacity to secure our
environments without running into adverse issues. We recommend scaling
Corelight sensors when CPU utilization is over 70% for over 120
seconds.

### Deployment

The variables for this module all have default values that can be overwritten
to meet your naming and compliance standards.

Deployment examples can be found [here](examples).

## License

The project is licensed under the [MIT][] license.

[MIT]: LICENSE
