# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

# -----------------------------------------------------------------------------
# Subnets
# -----------------------------------------------------------------------------

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets."
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "IDs of the private database subnets."
  value       = aws_subnet.private_db[*].id
}

output "private_cache_subnet_ids" {
  description = "IDs of the private cache subnets."
  value       = aws_subnet.private_cache[*].id
}

# -----------------------------------------------------------------------------
# Security Groups
# -----------------------------------------------------------------------------

output "nlb_security_group_id" {
  description = "ID of the Network Load Balancer security group."
  value       = aws_security_group.nlb.id
}

output "alb_security_group_id" {
  description = "ID of the Application Load Balancer security group."
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ID of the ECS task security group."
  value       = aws_security_group.ecs.id
}

output "aurora_security_group_id" {
  description = "ID of the Aurora security group."
  value       = aws_security_group.aurora.id
}

output "redis_security_group_id" {
  description = "ID of the ElastiCache Redis security group."
  value       = aws_security_group.redis.id
}