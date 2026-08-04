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
# Aurora Variables
# -----------------------------------------------------------------------------

variable "private_db_subnet_ids" {
  description = "IDs of the private database subnets used by Aurora."
  type        = list(string)
}

variable "aurora_security_group_id" {
  description = "ID of the security group attached to the Aurora cluster."
  type        = string
}

variable "database_name" {
  description = "Name of the initial database created in the Aurora cluster."
  type        = string
}

variable "master_username" {
  description = "Master username for the Aurora cluster."
  type        = string
  sensitive   = true
}

variable "master_password" {
  description = "Master password for the Aurora cluster."
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "Instance class used by Aurora cluster instances."
  type        = string
}