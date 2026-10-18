# Pipeline artifact storage
resource "aws_s3_bucket" "cicd_artifacts" {

  bucket = "zhu-prd-test2-cicd-artifacts-043300555595"
  tags = {
    Name = "zhu-prd-test2-cicd-artifacts"
  }
}

resource "aws_s3_bucket_versioning" "cicd_artifacts" {

  bucket = aws_s3_bucket.cicd_artifacts.id

  versioning_configuration {

    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cicd_artifacts" {

  bucket = aws_s3_bucket.cicd_artifacts.id

  rule {

    apply_server_side_encryption_by_default {

      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cicd_artifacts" {
  bucket = aws_s3_bucket.cicd_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Delivery pipeline
resource "aws_codepipeline" "prd_test2" {

  execution_mode = "SUPERSEDED"
  name           = "zhu-prd-ecs-test2-pipeline"

  pipeline_type = "V1"

  role_arn = "arn:aws:iam::043300555595:role/zhu-prd-codepipeline-role"

  artifact_store {

    location = aws_s3_bucket.cicd_artifacts.bucket

    type = "S3"
  }

  # Source stage
  stage {

    name = "Source"

    action {

      name = "Source"

      namespace = "SourceVariables"

      output_artifacts = ["SourceOutput"]

      category = "Source"
      owner    = "AWS"
      provider = "CodeStarSourceConnection"
      region   = "ap-northeast-1"

      run_order = 1
      version   = "1"

      configuration = {
        BranchName = var.github_branch

        ConnectionArn = local.github_connection_arn
        DetectChanges = "true"

        FullRepositoryId = var.github_repository

        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  # Build stage
  stage {
    name = "Build"
    action {
      category = "Build"
      configuration = {
        ProjectName = aws_codebuild_project.prd_test2.name
      }

      input_artifacts = ["SourceOutput"]
      name            = "Build"

      namespace        = "BuildVariables"
      output_artifacts = ["BuildOutput"]
      owner            = "AWS"
      provider         = "CodeBuild"
      region           = "ap-northeast-1"
      run_order        = 1
      version          = 1
    }
  }

  # Approval stage
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

  # Deploy stage
  stage {
    name = "Deploy"
    action {
      category = "Deploy"

      input_artifacts = ["BuildOutput"]
      name            = "Deploy"
      namespace       = "DeployVariables"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      region          = "ap-northeast-1"
      run_order       = 1
      version         = 1
      configuration = {

        AppSpecTemplateArtifact = "BuildOutput"
        AppSpecTemplatePath     = "appspec.yaml"

        ApplicationName     = aws_codedeploy_app.prd_test2.name
        DeploymentGroupName = aws_codedeploy_deployment_group.prd_test2.deployment_group_name

        Image1ArtifactName  = "BuildOutput"
        Image1ContainerName = "IMAGE1_NAME"

        TaskDefinitionTemplateArtifact = "BuildOutput"
        TaskDefinitionTemplatePath     = "taskdef.json"
      }
    }
  }
}
