# -----------------------------------------------------------------------------
# CodePipeline
# CodeCommit → CodeBuild → CodeDeploy (ECS Blue/Green) のデリバリーパイプライン。
# -----------------------------------------------------------------------------

# Pipeline が Source / Build 成果物を一時保存する専用 S3 Bucket。
# Terraform State 用 Bucket とは分離し、CI/CD のデータだけを管理する。
resource "aws_s3_bucket" "cicd_artifacts" {
  bucket = "zhu-prd-test2-cicd-artifacts-043300555595"

  tags = {
    Name = "zhu-prd-test2-cicd-artifacts"
  }
}

# 過去のデプロイ成果物を追跡できるよう、オブジェクトのバージョニングを有効にする。
resource "aws_s3_bucket_versioning" "cicd_artifacts" {
  bucket = aws_s3_bucket.cicd_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Artifact は保存時にも暗号化する。AWS 管理キー AES256 を使用する。
resource "aws_s3_bucket_server_side_encryption_configuration" "cicd_artifacts" {
  bucket = aws_s3_bucket.cicd_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Artifact Bucket をインターネットへ公開しない。
resource "aws_s3_bucket_public_access_block" "cicd_artifacts" {
  bucket = aws_s3_bucket.cicd_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Source → Build → Manual Approval → Deploy を連結し、PRD 反映前に承認を必須にする。
resource "aws_codepipeline" "prd_test2" {
  execution_mode = "SUPERSEDED"
  name           = "zhu-prd-ecs-test2-pipeline"
  pipeline_type  = "V1"
  # 既存の CodePipeline Service Role を使用する。
  role_arn = "arn:aws:iam::043300555595:role/zhu-prd-codepipeline-role"

  artifact_store {
    location = aws_s3_bucket.cicd_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      namespace        = "SourceVariables"
      output_artifacts = ["SourceOutput"]
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      region           = "ap-northeast-1"
      run_order        = 1
      version          = "1"

      configuration = {
        BranchName           = "main"
        OutputArtifactFormat = "Code_ZIP"
        PollForSourceChanges = "false"
        RepositoryName       = aws_codecommit_repository.prd_test2.repository_name
      }
    }
  }

  stage {
    name = "Build"
    action {
      category = "Build"
      configuration = {
        ProjectName = aws_codebuild_project.prd_test2.name
      }
      input_artifacts  = ["SourceOutput"]
      name             = "Build"
      namespace        = "BuildVariables"
      output_artifacts = ["BuildOutput"]
      owner            = "AWS"
      provider         = "CodeBuild"
      region           = "ap-northeast-1"
      run_order        = 1
      version          = 1
    }
  }

  stage {
    name = "Approval"

    action {
      category  = "Approval"
      name      = "ApproveProductionDeployment"
      owner     = "AWS"
      provider  = "Manual"
      region    = "ap-northeast-1"
      run_order = 1
      version   = "1"

      configuration = {
        CustomData = "Approve deployment of test2 to the PRD ECS service."
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      category = "Deploy"
      configuration = {
        AppSpecTemplateArtifact        = "BuildOutput"
        AppSpecTemplatePath            = "appspec.yaml"
        ApplicationName                = aws_codedeploy_app.prd_test2.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.prd_test2.deployment_group_name
        Image1ArtifactName             = "BuildOutput"
        Image1ContainerName            = "IMAGE1_NAME"
        TaskDefinitionTemplatePath     = "taskdef.json"
        TaskDefinitionTemplateArtifact = "BuildOutput"
      }
      input_artifacts = ["BuildOutput"]
      name            = "Deploy"
      namespace       = "DeployVariables"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      region          = "ap-northeast-1"
      run_order       = 1
      version         = 1
    }
  }
}
