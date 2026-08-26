# -----------------------------------------------------------------------------
# Security Groups
# 通信経路を NLB → ALB → ECS に限定する。
# -----------------------------------------------------------------------------

# 最初の入口で公開ポート以外を遮断するための NLB 用 SG。
resource "aws_security_group" "nlb" {
  name        = "zhu-prd-nlb-sg"
  description = "Inbound access control for the Network Load Balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "zhu-prd-nlb-sg"
  }
}

# ALB への到達元を NLB に限定し、直接アクセスを防ぐための SG。
resource "aws_security_group" "alb" {
  name        = "zhu-prd-alb-sg"
  description = "Allow NLB traffic to the internal Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "zhu-prd-alb-sg"
  }
}

# コンテナへの到達元を ALB に限定する最終防御層の SG。
resource "aws_security_group" "ecs" {
  name        = "zhu-prd-ecs-sg"
  description = "Allow only ALB traffic to ECS tasks"
  vpc_id      = var.vpc_id

  tags = {
    Name = "zhu-prd-ecs-sg"
  }
}

# インターネットから NLB の HTTPS ポートへのアクセスを許可する。
# 一般的な HTTPS リクエストを NLB の 443 で受ける。
resource "aws_vpc_security_group_ingress_rule" "nlb_443" {
  security_group_id = aws_security_group.nlb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS from the internet"
}

# Blue/Green のテストリクエスト用に 10443 も NLB で受ける。
resource "aws_vpc_security_group_ingress_rule" "nlb_10443" {
  security_group_id = aws_security_group.nlb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 10443
  to_port           = 10443
  ip_protocol       = "tcp"
  description       = "HTTPS alternate port from the internet"
}

# NLB から ALB の対応するリスナーポートへの転送を許可する。
# NLB から ALB の本番 HTTPS Listener だけへ転送を許可する。
resource "aws_vpc_security_group_egress_rule" "nlb_to_alb_443" {
  security_group_id            = aws_security_group.nlb.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Forward HTTPS to ALB"
}

# NLB から ALB のテスト Listener だけへ転送を許可する。
resource "aws_vpc_security_group_egress_rule" "nlb_to_alb_10443" {
  security_group_id            = aws_security_group.nlb.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 10443
  to_port                      = 10443
  ip_protocol                  = "tcp"
  description                  = "Forward alternate HTTPS to ALB"
}

# ALB は NLB 経由の本番トラフィックだけを受ける。
resource "aws_vpc_security_group_ingress_rule" "alb_from_nlb_443" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.nlb.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "HTTPS from NLB"
}

# ALB は NLB 経由のテストトラフィックだけを受ける。
resource "aws_vpc_security_group_ingress_rule" "alb_from_nlb_10443" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.nlb.id
  from_port                    = 10443
  to_port                      = 10443
  ip_protocol                  = "tcp"
  description                  = "Alternate HTTPS from NLB"
}

# ALB から ECS コンテナの HTTP/80 へのアクセスを許可する。
# ALB からアプリケーションの HTTP ポートだけへ転送を許可する。
resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  description                  = "HTTP to ECS tasks"
}

# ECS タスクは ALB 以外からのアプリケーション通信を受け付けない。
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  description                  = "HTTP from ALB"
}

# ECR、CloudWatch Logs、DNS、外部 API への通信を許可する。
# イメージ取得、ログ送信、DNS、外部 API 呼び出しのための ECS 出力通信。
resource "aws_vpc_security_group_egress_rule" "ecs_outbound" {
  security_group_id = aws_security_group.ecs.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Outbound traffic for ECS tasks"
}
