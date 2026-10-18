# Input variables
variable "vpc_id" { type = string }
variable "alb_subnet_ids" { type = list(string) }
variable "alb_security_group_id" { type = string }

variable "alb_certificate_arn" {
  type     = string
  default  = null
  nullable = true
}
