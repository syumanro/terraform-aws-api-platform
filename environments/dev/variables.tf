# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR Block"
  type        = string
}

variable "availability_zones" {
  description = "Availability Zones used by the network module."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets."
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for the private application subnets."
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for the private database subnets."
  type        = list(string)
}

variable "private_cache_subnet_cidrs" {
  description = "CIDR blocks for the private cache subnets."
  type        = list(string)
}

# variable "alb_certificate_arn" {
#   description = "ARN of the ACM certificate used by the ALB HTTPS listener."
#   type        = string
# }

variable "desired_count" {
  description = "Desired number of ECS tasks."
  type        = number
}

variable "health_check_grace_period_seconds" {
  description = "Time that ECS ignores unhealthy load balancer health checks after task startup."
  type        = number
}

variable "task_definition_arn" {
  description = "ARN of the ECS task definition managed by CI/CD."
  type        = string
}

# -----------------------------------------------------------------------------
# Aurora Variables
# -----------------------------------------------------------------------------

variable "database_name" {
  description = "Name of the initial Aurora database."
  type        = string
}

variable "database_master_username" {
  description = "Master username for the Aurora cluster."
  type        = string
  sensitive   = true
}

variable "database_master_password" {
  description = "Master password for the Aurora cluster."
  type        = string
  sensitive   = true
}

variable "aurora_instance_class" {
  description = "Instance class used by Aurora cluster instances."
  type        = string
}

# -----------------------------------------------------------------------------
# Redis Variables
# -----------------------------------------------------------------------------

variable "redis_node_type" {
  description = "Node type used by the ElastiCache replication group."
  type        = string
}

variable "redis_engine_version" {
  description = "Valkey engine version used by the ElastiCache replication group."
  type        = string
}
