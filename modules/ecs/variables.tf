# -----------------------------------------------------------------------------
# Common Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used for naming AWS resources."
  type        = string
}

variable "environment" {
  description = "Environment name such as dev, stg, or prod."
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to AWS resources."
  type        = map(string)
}

# -----------------------------------------------------------------------------
# ECS Variables
# -----------------------------------------------------------------------------

variable "private_app_subnet_ids" {
  description = "IDs of the private application subnets used by ECS tasks."
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ID of the security group attached to ECS tasks."
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group used by the ECS service."
  type        = string
}

variable "health_check_grace_period_seconds" {
  description = "Time that ECS ignores unhealthy ALB health checks after a task starts."
  type        = number
}

variable "desired_count" {
  description = "Desired number of ECS tasks."
  type        = number
}

variable "task_definition_arn" {
  description = "ARN of the ECS task definition managed outside Terraform."
  type        = string
}