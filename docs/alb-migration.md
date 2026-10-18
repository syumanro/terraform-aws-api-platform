# ALB-only architecture

The request path is now `Internet → public ALB → private ECS tasks`.
GitHub, CodePipeline, CodeBuild, ECR, CodeDeploy, and ECS Auto Scaling retain their existing roles.

## Configuration changes

- The ALB uses the two public subnets and accepts production traffic on port 443 and test traffic on port 10443.
- The ECS service continues to use private subnets without public IP addresses. Its application port accepts traffic from the ALB security group only.
- The NLB, its two TCP listeners, two ALB target groups, target registrations, security group, and forwarding rules are removed.
- The two ECS IP target groups and both ALB listeners remain available for CodeDeploy Blue/Green deployments.
- Terraform manages the deployment group's listener references so replacement ALB listeners are propagated to CodeDeploy. CodeDeploy manages each listener's active default target group.
- The network module exports `public_subnet_ids`; the load-balancing module accepts `alb_subnet_ids` and no longer accepts NLB inputs or ECS subnets.
- The root DNS output changes from `nlb_dns_name` to `alb_dns_name`.

## Access

Without an ACM certificate, the existing learning configuration uses HTTP on both ports:

```powershell
cd common/prd_test2
$albDns = terraform output -raw alb_dns_name
curl.exe "http://${albDns}:443/health"
curl.exe "http://${albDns}:10443/health"
```

These commands assume a successful infrastructure apply and application deployment.
With a certificate, use `https://` and a domain covered by that certificate, pointing its DNS record to the ALB. The generated ALB DNS name is normally not covered by your ACM certificate.

Port 10443 retains the previous public IPv4 access scope. It is a test traffic entry point, not an authentication boundary.

## Existing deployments

Run `terraform plan -var-file=prd.tfvars` before applying the change to an existing environment.
No AWS infrastructure is changed merely by editing these files.

Changing the existing ALB from internal to internet-facing requires replacement. The fixed ALB name can require destroying the old ALB before creating its replacement, so plan for interruption and a new DNS endpoint. References in listeners, ECS, and CodeDeploy must be updated together. The ALB security group uses a generated name prefix and creation before destruction to avoid a fixed-name collision during its replacement.

`modules/network/moved.tf` maps the five previous public-network resource addresses to their new names. The public subnet CIDRs are unchanged, so a rename alone should not recreate the subnets. Keep these migration declarations for environments that have not upgraded yet. The NLB resources are intentionally removed rather than moved to the ALB.

Review any external DNS records or scripts that use the old NLB endpoint or `nlb_dns_name` output and change them to the new ALB endpoint.

## Validation and remaining prerequisites

```powershell
cd common/prd_test2
terraform fmt -check -recursive
terraform validate
terraform test
```

The four tests use mocked AWS providers, including their `command = apply` runs. They do not create, update, or delete real AWS resources. They verify the public/private network split, ALB ingress and ECS port restrictions, and both certificate modes.

Actual connectivity still depends on the existing VPC, IAM roles, GitHub connection, and private-task egress configuration. This change does not add a NAT gateway or VPC endpoints; private tasks still require the relevant paths to pull images and send logs. Offline validation is not a replacement for an AWS plan or a deployment test.
