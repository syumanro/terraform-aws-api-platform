# -----------------------------------------------------------------------------
# Network Load Balancer → Application Load Balancer
# TCP を終端せずに、同一ポートの内部 ALB リスナーへ透過的に転送する。
# -----------------------------------------------------------------------------

# インターネットからの TCP 接続を受け、ALB へ転送する入口を作成する。
resource "aws_lb" "nlb" {
  # false を指定し、インターネット向け NLB として作成する。
  name               = "zhu-prd-nlb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.nlb.id]
  # インターネット公開用に新規作成した 2 AZ のパブリック Subnet へ配置する。
  subnets = [aws_subnet.nlb_a.id, aws_subnet.nlb_c.id]

  tags = {
    Name = "zhu-prd-nlb"
  }
}

# 標準 HTTPS ポートを TLS 終端せずに ALB:443 へ透過転送する。
resource "aws_lb_listener" "nlb_443" {
  # NLB の TCP/443 を、ALB の HTTPS/443 に対応するターゲットグループへ転送する。
  load_balancer_arn = aws_lb.nlb.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_to_alb_443.arn
  }
}

# Blue/Green のテスト用ポートを ALB:10443 へ透過転送する。
resource "aws_lb_listener" "nlb_10443" {
  # NLB の TCP/10443 を、ALB の HTTPS/10443 に対応するターゲットグループへ転送する。
  load_balancer_arn = aws_lb.nlb.arn
  port              = 10443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_to_alb_10443.arn
  }
}

# ALB を NLB のターゲットとして登録する場合は target_type を "alb" にする。
# ターゲットグループのポートは、転送先 ALB リスナーのポートと一致させる必要がある。
# NLB で ALB をターゲットとして扱うため、target_type = "alb" を使用する。
resource "aws_lb_target_group" "nlb_to_alb_443" {
  # NLB:443 から ALB:443 へ転送するためのターゲットグループ。
  name        = "zhu-prd-test2-nlb-alb-443"
  port        = 443
  protocol    = "TCP"
  target_type = "alb"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    protocol            = var.alb_certificate_arn == null ? "HTTP" : "HTTPS"
    port                = "traffic-port"
    path                = "/"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-499"
  }

  tags = {
    Name = "zhu-prd-test2-nlb-alb-443"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# テスト用ポートも本番と分離してヘルスチェックできるよう専用 TG を作成する。
resource "aws_lb_target_group" "nlb_to_alb_10443" {
  # NLB:10443 から ALB:10443 へ転送するためのターゲットグループ。
  name        = "zhu-prd-test2-nlb-alb-10443"
  port        = 10443
  protocol    = "TCP"
  target_type = "alb"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    protocol            = var.alb_certificate_arn == null ? "HTTP" : "HTTPS"
    port                = "traffic-port"
    path                = "/"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-499"
  }

  tags = {
    Name = "zhu-prd-test2-nlb-alb-10443"
  }


  lifecycle {
    create_before_destroy = true
  }
}


# NLB の 443 用 TG に内部 ALB を登録する。
resource "aws_lb_target_group_attachment" "nlb_to_alb_443" {
  # 作成した内部 ALB を NLB の 443 用ターゲットグループに登録する。
  target_group_arn = aws_lb_target_group.nlb_to_alb_443.arn
  target_id        = aws_lb.alb.arn
  port             = 443

  depends_on = [aws_lb_listener.alb_443]
}

# NLB の 10443 用 TG に同じ内部 ALB を登録する。
resource "aws_lb_target_group_attachment" "nlb_to_alb_10443" {
  # 作成した内部 ALB を NLB の 10443 用ターゲットグループに登録する。
  target_group_arn = aws_lb_target_group.nlb_to_alb_10443.arn
  target_id        = aws_lb.alb.arn
  port             = 10443

  depends_on = [aws_lb_listener.alb_10443]
}

# -----------------------------------------------------------------------------
# 内部 Application Load Balancer
# NLB から受信した通信を、ホスト名ごとに ECS のターゲットグループへ振り分ける。
# -----------------------------------------------------------------------------

# L7 のホスト判定と CodeDeploy のトラフィック切替を行う内部 ALB。
resource "aws_lb" "alb" {
  name               = "zhu-prd-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  # ALB は複数 AZ に配置する必要があるため、作成した ECS 用サブネットを指定する。
  subnets                    = [aws_subnet.ecs_a.id, aws_subnet.ecs_c.id]
  drop_invalid_header_fields = true

  tags = {
    Name = "zhu-prd-alb"
  }
}

# 通常ユーザー向け HTTPS リスナー。Production TG にルーティングする。
resource "aws_lb_listener" "alb_443" {
  # HTTPS の標準ポート用リスナー。該当するリスナールールがない場合は 404 を返す。
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = var.alb_certificate_arn == null ? "HTTP" : "HTTPS"
  ssl_policy        = var.alb_certificate_arn == null ? null : "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.alb_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg01.arn
  }
}

# 新バージョン確認専用の HTTPS リスナー。CodeDeploy の test traffic に使う。
resource "aws_lb_listener" "alb_10443" {
  # HTTPS の追加ポート用リスナー。443 と同じ証明書を使用する。
  load_balancer_arn = aws_lb.alb.arn
  port              = 10443
  protocol          = var.alb_certificate_arn == null ? "HTTP" : "HTTPS"
  ssl_policy        = var.alb_certificate_arn == null ? null : "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.alb_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg02.arn
  }
}


# 本番ポートで指定ホスト名を tg01 へ転送するルール。
resource "aws_lb_listener_rule" "prd_443" {
  # 443 宛てで指定ホスト名に一致したリクエストを tg01 へ転送する。
  listener_arn = aws_lb_listener.alb_443.arn
  priority     = 20
  tags = {
    Name = "prd"
  }
  lifecycle {
    ignore_changes = [
      action
    ]
  }
  action {
    order            = 1
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg01.arn
  }
  condition {
    host_header {
      values = ["prd_test2_test.com"]
    }
  }
  depends_on = [aws_lb_target_group.tg01, aws_lb_target_group.tg02]
}

# テストポートで指定ホスト名を tg02 へ転送するルール。
resource "aws_lb_listener_rule" "prd_10443" {
  # 10443 宛てで指定ホスト名に一致したリクエストを tg02 へ転送する。
  listener_arn = aws_lb_listener.alb_10443.arn
  priority     = 20
  tags = {
    Name = "prd"
  }
  lifecycle {
    ignore_changes = [
      action
    ]
  }
  action {
    order            = 1
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg02.arn
  }
  condition {
    host_header {
      values = ["prd_test2_test.com"]
    }
  }
  depends_on = [aws_lb_target_group.tg01, aws_lb_target_group.tg02]
}

# Blue/Green の一方として ECS タスクの HTTP/80 を受ける本番側 TG。
resource "aws_lb_target_group" "tg01" {
  # ALB の 443 リスナールールから転送される ECS タスク（IP）用ターゲットグループ。
  deregistration_delay              = 300
  ip_address_type                   = "ipv4"
  load_balancing_algorithm_type     = "round_robin"
  load_balancing_anomaly_mitigation = "off"
  load_balancing_cross_zone_enabled = "use_load_balancer_configuration"
  name                              = "zhu-prd-test2-alb-ecs-tg-01"
  port                              = 80
  protocol                          = "HTTP"
  protocol_version                  = "HTTP1"
  target_type                       = "ip"
  vpc_id                            = var.vpc_id
  tags = {
    Name = "zhu-prd-test2-alb-ecs-tg-01"
  }
  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
  stickiness {
    cookie_duration = 86400
    enabled         = false
    type            = "lb_cookie"
  }
}

# Blue/Green デプロイ時に新しいタスクセットを検証するもう一方の TG。
resource "aws_lb_target_group" "tg02" {
  # ALB の 10443 リスナールールから転送される ECS タスク（IP）用ターゲットグループ。
  deregistration_delay              = 300
  ip_address_type                   = "ipv4"
  load_balancing_algorithm_type     = "round_robin"
  load_balancing_anomaly_mitigation = "off"
  load_balancing_cross_zone_enabled = "use_load_balancer_configuration"
  name                              = "zhu-prd-test2-alb-ecs-tg-02"
  port                              = 80
  protocol                          = "HTTP"
  protocol_version                  = "HTTP1"
  target_type                       = "ip"
  vpc_id                            = var.vpc_id
  tags = {
    Name = "zhu-prd-test2-alb-ecs-tg-02"
  }
  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
  stickiness {
    cookie_duration = 86400
    enabled         = false
    type            = "lb_cookie"
  }
}








