# -----------------------------------------------------------------------------
# CodeCommit
# CI/CD パイプラインのソースコードリポジトリ。
# -----------------------------------------------------------------------------

# アプリケーション、BuildSpec、AppSpec を一元管理し、Pipeline の変更検知元にする。
resource "aws_codecommit_repository" "prd_test2" {
  repository_name = "zhu-prd-ecs-test2"
  description     = "Source repository for the zhu-prd ECS test2 service"

  tags = {
    Name = "zhu-prd-ecs-test2"
  }
}
