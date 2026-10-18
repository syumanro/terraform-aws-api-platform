# Outputs
output "public_subnet_ids" { value = [aws_subnet.public_a.id, aws_subnet.public_c.id] }
output "ecs_subnet_ids" { value = [aws_subnet.ecs_a.id, aws_subnet.ecs_c.id] }
