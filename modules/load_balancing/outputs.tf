output "nlb_dns_name" { value = aws_lb.nlb.dns_name }
output "production_target_group_arn" { value = aws_lb_target_group.tg01.arn }
output "production_target_group_name" { value = aws_lb_target_group.tg01.name }
output "test_target_group_name" { value = aws_lb_target_group.tg02.name }
output "production_listener_arn" { value = aws_lb_listener.alb_443.arn }
output "test_listener_arn" { value = aws_lb_listener.alb_10443.arn }
