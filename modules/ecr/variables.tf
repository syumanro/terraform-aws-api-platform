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