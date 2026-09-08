variable "vpc_id" { type = string }
variable "nlb_subnet_ids" { type = list(string) }
variable "ecs_subnet_ids" { type = list(string) }
variable "nlb_security_group_id" { type = string }
variable "alb_security_group_id" { type = string }
variable "alb_certificate_arn" {
  type     = string
  default  = null
  nullable = true
}
