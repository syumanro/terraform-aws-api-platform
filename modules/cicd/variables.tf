variable "github_repository" { type = string }
variable "github_branch" { type = string }
variable "github_connection_arn" {
  type     = string
  default  = null
  nullable = true
}
variable "ecr_repository_uri" { type = string }
variable "ecr_registry_id" { type = string }
variable "ecs_cluster_name" { type = string }
variable "ecs_service_name" { type = string }
variable "production_listener_arn" { type = string }
variable "test_listener_arn" { type = string }
variable "production_target_group_name" { type = string }
variable "test_target_group_name" { type = string }
