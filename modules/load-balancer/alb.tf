# -----------------------------------------------------------------------------
# Internal Application Load Balancer
# -----------------------------------------------------------------------------

resource "aws_lb" "alb" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.private_app_subnet_ids

  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-alb"
    }
  )
}

# -----------------------------------------------------------------------------
# ECS Target Group
# -----------------------------------------------------------------------------

resource "aws_lb_target_group" "ecs" {
  name                 = "${var.project_name}-${var.environment}-ecs-tg"
  port                 = 8080
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = var.alb_health_check_path
    matcher             = "200-399"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-ecs-tg"
    }
  )
}

# -----------------------------------------------------------------------------
# HTTP Listener
# -----------------------------------------------------------------------------

resource "aws_lb_listener" "alb_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }
}

# -----------------------------------------------------------------------------
# HTTPS Listener
# -----------------------------------------------------------------------------

# resource "aws_lb_listener" "alb_https" {
#   load_balancer_arn = aws_lb.alb.arn
#   port              = 443
#   protocol          = "HTTPS"
#   certificate_arn   = var.alb_certificate_arn
#   ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

#   default_action {
#     type = "fixed-response"

#     fixed_response {
#       content_type = "application/json"
#       message_body = jsonencode({
#         message = "Not Found"
#       })
#       status_code = "404"
#     }
#   }
# }
