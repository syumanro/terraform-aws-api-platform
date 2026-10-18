# GitHub connection
resource "aws_codestarconnections_connection" "github" {

  count         = var.github_connection_arn == null ? 1 : 0
  name          = "zhu-prd-test2-github"
  provider_type = "GitHub"
}

# Connection selection
locals {
  github_connection_arn = coalesce(

    var.github_connection_arn,

    try(aws_codestarconnections_connection.github[0].arn, null)
  )
}
