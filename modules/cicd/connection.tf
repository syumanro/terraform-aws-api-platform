# 既存の接続ARNが指定されない場合に、GitHub App用の接続を作成する。
# 作成後、AWSコンソールでGitHubへの認証を完了してAVAILABLE状態にする必要がある。
resource "aws_codestarconnections_connection" "github" {
  count = var.github_connection_arn == null ? 1 : 0

  name          = "zhu-prd-test2-github"
  provider_type = "GitHub"
}

locals {
  github_connection_arn = coalesce(
    var.github_connection_arn,
    try(aws_codestarconnections_connection.github[0].arn, null)
  )
}
