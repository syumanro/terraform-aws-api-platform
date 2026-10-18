# Application Load Balancer
resource "aws_lb" "alb" {
  name                       = "zhu-prd-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_security_group_id]
  subnets                    = var.alb_subnet_ids
  drop_invalid_header_fields = true
  tags = {
    Name = "zhu-prd-alb"
  }
}

# ALB listeners
resource "aws_lb_listener" "alb_443" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = var.alb_certificate_arn == null ? "HTTP" : "HTTPS"
  ssl_policy        = var.alb_certificate_arn == null ? null : "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.alb_certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg01.arn
  }

  # CodeDeploy owns the active target group after the initial deployment.
  lifecycle {
    ignore_changes = [default_action]
  }
}

resource "aws_lb_listener" "alb_10443" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 10443
  protocol          = var.alb_certificate_arn == null ? "HTTP" : "HTTPS"
  ssl_policy        = var.alb_certificate_arn == null ? null : "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.alb_certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg02.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

# Host routing rules
resource "aws_lb_listener_rule" "prd_443" {
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

resource "aws_lb_listener_rule" "prd_10443" {
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

# ECS target groups
resource "aws_lb_target_group" "tg01" {
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

resource "aws_lb_target_group" "tg02" {
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
