# Terraform AWS API Platform

Enterprise AWS API Platform built with Terraform.

## Architecture

- VPC
- NLB
- ALB
- ECS (Fargate)
- ECR
- CloudWatch
- CodeDeploy
- CodeBuild
- CodePipeline (GitHub source via AWS CodeConnections)

## Project Structure

- `common/prd_test2`: production environment root module
- `modules/network`: subnets, route tables, and internet gateway
- `modules/security_groups`: NLB, ALB, and ECS traffic controls
- `modules/load_balancing`: NLB, ALB, listeners, and target groups
- `modules/ecs`: ECS cluster, service, task definition, logs, and service discovery
- `modules/autoscaling`: ECS scaling policies and alarms
- `modules/ecr`: container registry, image scanning, and lifecycle policy
- `modules/cicd`: GitHub source, CodeBuild, CodeDeploy, and CodePipeline
- docs

## GitHub connection

CodeCommit is not used. By default, CodePipeline reads the current GitHub
repository through a Terraform-managed AWS CodeConnections connection. After
the first apply, authorize that connection for GitHub in the AWS console. Set
`github_connection_arn` only when reusing an existing authorized connection.

新規接続を作る場合は、先に接続だけを作成してGitHub認証を完了します。

```powershell
terraform apply -target='module.cicd.aws_codestarconnections_connection.github'
```

接続が `AVAILABLE` になった後、通常の `terraform apply` を実行します。

## Test application

The repository root contains the deployable test application and its pipeline
templates:

- `Dockerfile` builds an Nginx image serving `app/index.html` and `/health`.
- `buildspec.yml` tests the container, pushes the commit-tagged image to ECR,
  and emits `imageDetail.json` for CodeDeploy.
- `appspec.yaml` defines the ECS Blue/Green deployment.
- `taskdef.json` defines the Fargate task revision used by CodeDeploy.

```powershell
cd common/prd_test2
Copy-Item prd.tfvars.example prd.tfvars
terraform init
terraform plan -var-file=prd.tfvars
```

既存環境へ適用する場合、`moved` ブロックによりCodeCommit以外のリソースは
モジュール内へstate移行されます。CodeCommitリポジトリは削除対象になるため、
必要なソースがGitHubへpush済みであることを確認してからapplyしてください。
