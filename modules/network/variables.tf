# -----------------------------------------------------------------------------
# Network Module Variables
# -----------------------------------------------------------------------------

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

variable "common_tags" {
  description = "Common resource tags"
  type        = map(string)
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

