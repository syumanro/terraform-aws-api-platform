# -----------------------------------------------------------------------------
# NLB Ingress Rules
# -----------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "nlb_http_from_internet" {
  security_group_id = aws_security_group.nlb.id

  description = "Allows inbound HTTP traffic from the internet."
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

# -----------------------------------------------------------------------------
# NLB Egress Rules
# -----------------------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "nlb_http_to_alb" {
  security_group_id = aws_security_group.nlb.id

  description                  = "Allows HTTP traffic from the NLB to the internal ALB."
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

# -----------------------------------------------------------------------------
# ALB Ingress Rules
# -----------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "alb_http_from_nlb" {
  security_group_id = aws_security_group.alb.id

  description                  = "Allows HTTP traffic from the NLB."
  referenced_security_group_id = aws_security_group.nlb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

# -----------------------------------------------------------------------------
# ALB Egress Rules
# -----------------------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id = aws_security_group.alb.id

  description                  = "Allows application traffic from the ALB to ECS tasks."
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}

# -----------------------------------------------------------------------------
# ECS Ingress Rules
# -----------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id = aws_security_group.ecs.id

  description                  = "Allows application traffic from the ALB."
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}

# -----------------------------------------------------------------------------
# ECS Egress Rules
# -----------------------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "ecs_https" {
  security_group_id = aws_security_group.ecs.id

  description = "Allows HTTPS traffic to AWS services and external endpoints."
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_aurora" {
  security_group_id = aws_security_group.ecs.id

  description                  = "Allows MySQL traffic from ECS tasks to Aurora."
  referenced_security_group_id = aws_security_group.aurora.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_redis" {
  security_group_id = aws_security_group.ecs.id

  description                  = "Allows Redis traffic from ECS tasks to ElastiCache."
  referenced_security_group_id = aws_security_group.redis.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
}

# -----------------------------------------------------------------------------
# Aurora Ingress Rules
# -----------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "aurora_from_ecs" {
  security_group_id = aws_security_group.aurora.id

  description                  = "Allows MySQL traffic from ECS tasks."
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}

# -----------------------------------------------------------------------------
# Redis Ingress Rules
# -----------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "redis_from_ecs" {
  security_group_id = aws_security_group.redis.id

  description                  = "Allows Redis traffic from ECS tasks."
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
}