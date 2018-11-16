# Application Task

Write Terraform script(s) to create a secure and scalable AWS environment to support a web application.

## Requirements

* SPA frontend.
* REST API server.
* Job queue.
* SQL database.
* HTTPS for the frontend and API.

## Architecture & Features

The front-end application being a Single-Page Application (SPA) would be written in Angular or some other JavaScript framework. It would be comprised of only static content and would be well-suited to being hosted in an object store (s3) and delivered via content delivery network (CloudFront). Identity and Access Management (IAM) policies prohibit public access to the s3 bucket, since traffic costs are higher to an s3 bucket than they are from CloudFront. CloudFront has been configured to use an SSL certificate that was previously generated in Amazon's Certificate Manager. Although you can generate certificates with Terraform, you're only allowed to generate 10 certificates per month, so testing code that generates certificates over and over again can have *less-than-ideal consequences*.

The back-end application that I used to test with (not included) was built into a docker container and published to an Amazon Elastic Container Registry (ECR). There are two ECS clusters: One to host the front-end website containers and one to execute jobs from the batch job queue. Container instances can be added or removed by an auto-scaling policy. At the time of this writing, I don't actually know whether this would be triggered by the ECS service application auto-scaling policy or if you'd need to write a separate policy for the auto-scaling group (I assumed the former). The load-balancer in front of the container service performs SSL offload with an SSL cert that was (again) provisioned with Amazon's cert manager. The load-balancer and cluster instance(s) are all in the VPC's default subnet and can send traffic between each other, but inbound TCP80 and TCP443 are only permitted to the load-balancer.  There is also a security group that permits SSH access to the container instance *in the unlikely event that one should have need to perform unplanned docker maintenance*.

The data for the application would be hosted on an Aurora MySQL cluster. A security group limits connectivity to the database from the Virtual Private Cloud's subnet, although the cluster is not publicly accessible.  All components of this infrastructure (other than the CDN) are built in their own VPC. All components that can exist in some way in multiple availability zones (AZs) have been configured to do so through the use of dynamically provisioned subnets; if you change the region that this infrastructure is deployed in, terraform will automatically create one subnet for each AZ available in that region.

There are two demostrated ways of composing IAM policy documents in this repository: a file template and a native terraform policy document data source.


## Assumptions

The following assumptions have been made:

1. You already have a container image that contains the back-end/API application.
1. The back-end application listens on port 80.
1. You've pushed the container image to the AWS container registry. See [additional documentation](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/docker-basics.html#docker-basics-create-image) for details.
1. You've written your website front-end in static JavaScript/HTML.
1. The front-end website code will be uploaded to the s3 bucket named `fe_bucket_id`.
1. The front-end has been pre-configured to access your back-end API endpoint at the domain name `<api_dns_prefix.zone_name>`.
1. The zone for that domain name is managed in Route53.
1. You have previously set up an ECS environment in your AWS account manually, ie. the ecsAudoscaleRole, ecsServiceRole and ecsInstanceRole IAM policies exist.
1. You've already got SSL certificate(s) generated by or imported into ACM.
1. CICD for both parts of the app is not within the scope of this exercise.

## Input Parameters

There are several ways to pass input parameters/variables to Terraform. Please consult [the documentation](https://www.terraform.io/intro/getting-started/variables.html) to determine your preferred method.

| **Parameter Name** | **Value Type** | **Description** |
| ------------------ | -------------- | --------------- |
| `admin_cidr` | *String* | A CIDR block containing the IP address that can SSH into container instances. |
| `api_dns_prefix` | *String* | The DNS prefix associated with your API service. |
| `be_cert_arn` | *String* | The ARN for the SSL certificate that should be used to secure the backend API. |
| `database_name` | *String* | What name you want the database to have. |
| `database_pass` | *String* | The database admin user's password. |
| `database_user` | *String* | The name of the database admin user. |
| `ecr_name` | *String* | The name of your [Elastic Container Registry](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html). |
| `ecs_cluster_instance_type` | *String* | The type of AWS instance to use for hosting containers. |
| `fe_bucket_id` | *String* | A globally-unique name for the front-end content s3 bucket. |
| `fe_cert_arn` | *String* | The ARN for the SSL certificate that should be used to secure the frontend. **NOTE:** Because this cert is used by CloudFront, [it needs to exist in the us-east-1 region](https://docs.aws.amazon.com/acm/latest/userguide/acm-regions.html). |
| `key_pair_name` | *String* | The name of the key pair to use when launching instances (for SSH access). |
| `region` | *String* | The AWS region for this deployment. |
| `zone_name` | *String* | The name of the Route53 Hosted Zone associated with your API service. |

## Possible Enhancements

1. Logging.
1. Monitoring.
1. Alerting.
1. Use tagging and resource dependency between the ECS instance launch configuration and the database security group to limit connections from only instances instead of the entire VPC subnet.
1. Investigate whether you can use only IAM in place of or in addition to security groups [like you can do on GCP].
1. Write some useful output parameters.
1. Integrate some kind of CICD solution.
