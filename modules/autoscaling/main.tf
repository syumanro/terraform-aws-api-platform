# Scaling target
resource "aws_appautoscaling_target" "prd_test2" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU target tracking
resource "aws_appautoscaling_policy" "cpu_target_prd_test2" {
  name               = "${var.service_name}-cpu-utilization-target-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.prd_test2.resource_id
  scalable_dimension = aws_appautoscaling_target.prd_test2.scalable_dimension
  service_namespace  = aws_appautoscaling_target.prd_test2.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 40.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
    disable_scale_in   = false
  }
}

# Memory target tracking
resource "aws_appautoscaling_policy" "memory_target_prd_test2" {
  name               = "${var.service_name}-memory-utilization-target-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.prd_test2.resource_id
  scalable_dimension = aws_appautoscaling_target.prd_test2.scalable_dimension
  service_namespace  = aws_appautoscaling_target.prd_test2.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 60.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
    disable_scale_in   = false
  }
}
