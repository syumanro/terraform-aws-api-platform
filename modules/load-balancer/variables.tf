# -----------------------------------------------------------------------------
# Common
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
# Network
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the VPC."
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets."
  type        = list(string)
}

variable "private_app_subnet_ids" {
  description = "IDs of the private application subnets."
  type        = list(string)
}

variable "nlb_security_group_id" {
  description = "ID of the Network Load Balancer security group."
  type        = string
}

variable "alb_security_group_id" {
  description = "ID of the Application Load Balancer security group."
  type        = string
}

variable "alb_health_check_path" {
  description = "HTTP path used by the ALB to check ECS task health."
  type        = string
  default     = "/health"

  validation {
    condition     = startswith(var.alb_health_check_path, "/")
    error_message = "alb_health_check_path must start with '/'."
  }
}

# variable "alb_certificate_arn" {
#   description = "ARN of the ACM certificate used by the ALB HTTPS listener."
#   type        = string
# }
