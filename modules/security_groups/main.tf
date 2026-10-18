# Security groups
resource "aws_security_group" "alb" {
  name_prefix = "zhu-prd-alb-"
  description = "Client access to the public Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "zhu-prd-alb-sg"
  }

  # Allow replacement without colliding with the existing security group name.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecs" {
  name        = "zhu-prd-ecs-sg"
  description = "Allow only ALB traffic to ECS tasks"
  vpc_id      = var.vpc_id

  tags = {
    Name = "zhu-prd-ecs-sg"
  }
}

# Internet to ALB
resource "aws_vpc_security_group_ingress_rule" "alb_443" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Production listener from the internet"
}

resource "aws_vpc_security_group_ingress_rule" "alb_10443" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 10443
  to_port           = 10443
  ip_protocol       = "tcp"
  description       = "Test listener from the internet"
}

# ALB to ECS
resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  description                  = "HTTP to ECS tasks"
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  description                  = "HTTP from ALB"
}

# ECS outbound traffic
resource "aws_vpc_security_group_egress_rule" "ecs_outbound" {
  security_group_id = aws_security_group.ecs.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Outbound traffic for ECS tasks"
}
