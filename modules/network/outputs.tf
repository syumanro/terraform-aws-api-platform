output "nlb_subnet_ids" { value = [aws_subnet.nlb_a.id, aws_subnet.nlb_c.id] }
output "ecs_subnet_ids" { value = [aws_subnet.ecs_a.id, aws_subnet.ecs_c.id] }
