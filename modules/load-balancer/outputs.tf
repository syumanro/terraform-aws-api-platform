output "alb_arn" {
  description = "ARN of the internal Application Load Balancer."
  value       = aws_lb.alb.arn
}

output "alb_dns_name" {
  description = "DNS name of the internal Application Load Balancer."
  value       = aws_lb.alb.dns_name
}

output "alb_http_listener_arn" {
  description = "ARN of the ALB HTTP listener."
  value       = aws_lb_listener.alb_http.arn
}

output "ecs_target_group_arn" {
  description = "ARN of the ALB target group used by the ECS service."
  value       = aws_lb_target_group.ecs.arn
}

output "ecs_target_group_name" {
  description = "Name of the ALB target group used by the ECS service."
  value       = aws_lb_target_group.ecs.name
}

# output "alb_https_listener_arn" {
#   description = "ARN of the ALB HTTPS listener."
#   value       = aws_lb_listener.alb_https.arn
# }
