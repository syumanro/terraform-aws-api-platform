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
# Redis Variables
# -----------------------------------------------------------------------------

variable "private_cache_subnet_ids" {
  description = "IDs of the private cache subnets used by ElastiCache."
  type        = list(string)
}

variable "redis_security_group_id" {
  description = "ID of the security group attached to the ElastiCache replication group."
  type        = string
}

variable "node_type" {
  description = "Node type used by the ElastiCache replication group."
  type        = string
}

variable "engine_version" {
  description = "Valkey engine version used by the ElastiCache replication group."
  type        = string
}
