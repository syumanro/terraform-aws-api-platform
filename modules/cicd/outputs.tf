output "codepipeline_name" { value = aws_codepipeline.prd_test2.name }

output "github_connection_arn" { value = local.github_connection_arn }
