# -----------------------------------------------------------------------------
# CodeBuild
# ソースをビルドし、イメージを ECR へ push してデプロイ用アーティファクトを出力する。
# -----------------------------------------------------------------------------
# Docker イメージをビルドして ECR へ push し、CodeDeploy 用成果物を生成する。
resource "aws_codebuild_project" "prd_test2" {
  badge_enabled      = false
  build_timeout      = 60
  name               = "zhu-prd-test2-api-project"
  project_visibility = "PRIVATE"
  queued_timeout     = 480
  # 既存の CodeBuild Service Role を使用する。
  service_role = "arn:aws:iam::043300555595:role/zhu-prd-codebuild-role"

  artifacts {
    name                = "zhu-prd-test2-api-project"
    type                = "CODEPIPELINE"
    encryption_disabled = false
    packaging           = "NONE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

  }

  logs_config {
    cloudwatch_logs {
      group_name = "/ecs/codebuild/zhu-prd-test2-api"
      status     = "ENABLED"
    }
  }

  source {
    git_clone_depth = 0
    type            = "CODEPIPELINE"
  }

  tags = {
    Name = "zhu-prd-test2-build"
  }
}


# ビルド失敗の原因を確認できるよう CodeBuild のログを保持する。
resource "aws_cloudwatch_log_group" "codebuild_test2" {
  log_group_class   = "STANDARD"
  name              = "/ecs/codebuild/zhu-prd-test2-api"
  retention_in_days = 1827
  skip_destroy      = false
}
