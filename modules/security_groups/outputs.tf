output "nlb_security_group_id" { value = aws_security_group.nlb.id }
output "alb_security_group_id" { value = aws_security_group.alb.id }
output "ecs_security_group_id" { value = aws_security_group.ecs.id }
