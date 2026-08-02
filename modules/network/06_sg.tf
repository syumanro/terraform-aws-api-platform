# -----------------------------------------------------------------------------
# Network Load Balancer Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "nlb" {
  name        = "${var.project_name}-${var.environment}-nlb-sg"
  description = "Security group for the Network Load Balancer."
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-nlb-sg"
    }
  )
}

# -----------------------------------------------------------------------------
# Internal Application Load Balancer Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for the internal Application Load Balancer."
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-alb-sg"
    }
  )
}

# -----------------------------------------------------------------------------
# ECS Task Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "Security group for ECS tasks."
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-ecs-sg"
    }
  )
}

# -----------------------------------------------------------------------------
# Aurora Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "aurora" {
  name        = "${var.project_name}-${var.environment}-aurora-sg"
  description = "Security group for the Aurora MySQL cluster."
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-aurora-sg"
    }
  )
}

# -----------------------------------------------------------------------------
# ElastiCache Redis Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "redis" {
  name        = "${var.project_name}-${var.environment}-redis-sg"
  description = "Security group for the ElastiCache Redis cluster."
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-redis-sg"
    }
  )
}