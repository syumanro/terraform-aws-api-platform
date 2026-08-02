# -----------------------------------------------------------------------------
# Public Network Load Balancer
# -----------------------------------------------------------------------------

resource "aws_lb" "nlb" {
  name               = "${var.project_name}-${var.environment}-nlb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [var.nlb_security_group_id]
  subnets            = var.public_subnet_ids

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-nlb"
    }
  )
}

# -----------------------------------------------------------------------------
# NLB Target Group for the Internal ALB
# -----------------------------------------------------------------------------

resource "aws_lb_target_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-tg"
  port        = 80
  protocol    = "TCP"
  target_type = "alb"
  vpc_id      = var.vpc_id

  health_check {
    enabled  = true
    protocol = "HTTP"
    port     = "80"
    path     = "/"
    matcher  = "200-499"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-alb-tg"
    }
  )
}

# -----------------------------------------------------------------------------
# Internal ALB Registration
# -----------------------------------------------------------------------------

resource "aws_lb_target_group_attachment" "alb" {
  target_group_arn = aws_lb_target_group.alb.arn
  target_id        = aws_lb.alb.arn
  port             = 80

  depends_on = [
    aws_lb_listener.alb_http
  ]
}

# -----------------------------------------------------------------------------
# NLB TCP Listener
# -----------------------------------------------------------------------------

resource "aws_lb_listener" "nlb_tcp" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb.arn
  }
}