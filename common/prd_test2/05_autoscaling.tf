# -----------------------------------------------------------------------------
# ECS Service Auto Scaling
# Application Auto Scaling が ECS サービスの desired_count を管理する。
# CodeDeploy の Blue/Green デプロイ中も、サービスのスケール設定は維持される。
# -----------------------------------------------------------------------------

# ECS Service の desired_count を Application Auto Scaling が変更できるよう登録する。
resource "aws_appautoscaling_target" "prd_test2" {
  max_capacity       = 12
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.prd_test2.name}/${aws_ecs_service.prd_test2.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  lifecycle {
    ignore_changes = [max_capacity]
  }
}

# CPU 過負荷を検知して CPU Step Scaling を起動するアラーム。
resource "aws_cloudwatch_metric_alarm" "cpu_prd_test2" {
  # ECS サービスの平均 CPU 使用率が閾値以上の状態を検知する。
  alarm_name          = "${aws_ecs_service.prd_test2.name}-cpu-utilization-upper-limit-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    ClusterName = aws_ecs_cluster.prd_test2.name
    ServiceName = aws_ecs_service.prd_test2.name
  }

  # SNS Topic ARN を指定した場合に、ALARM 状態を通知する。
  alarm_actions = [aws_appautoscaling_policy.cpu_step_prd_test2.arn]
}

# CPU の平均利用率を目標値に保つように、タスク数を自動調整する。
# CPU が急上昇した場合に段階的にタスク数を増やすポリシー。
resource "aws_appautoscaling_policy" "cpu_step_prd_test2" {
  name               = "${aws_ecs_service.prd_test2.name}-cpu-utilization-step-scaling-policy"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.prd_test2.resource_id
  scalable_dimension = aws_appautoscaling_target.prd_test2.scalable_dimension
  service_namespace  = aws_appautoscaling_target.prd_test2.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "PercentChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"
    step_adjustment {
      metric_interval_lower_bound = 0
      metric_interval_upper_bound = 10
      scaling_adjustment          = 20
    }
    step_adjustment {
      metric_interval_lower_bound = 10
      scaling_adjustment          = 30
    }
  }
}


# CPU の平均利用率を目標値に保つように、タスク数を自動調整する。
# 通常時は CPU 平均利用率を目標値に保ち、過不足のない台数を維持する。
resource "aws_appautoscaling_policy" "cpu_target_prd_test2" {
  name               = "${aws_ecs_service.prd_test2.name}-cpu-utilization-target-scaling-policy"
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

# メモリ不足を検知して Memory Step Scaling を起動するアラーム。
resource "aws_cloudwatch_metric_alarm" "memory_prd_test2" {
  alarm_name          = "${aws_ecs_service.prd_test2.name}-memory-utilization-upper-limit-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    ClusterName = aws_ecs_cluster.prd_test2.name
    ServiceName = aws_ecs_service.prd_test2.name
  }

  # SNS Topic ARN を指定した場合に、ALARM 状態を通知する。
  alarm_actions = [aws_appautoscaling_policy.memory_step_prd_test2.arn]
}

# メモリが急上昇した場合に段階的にタスク数を増やすポリシー。
resource "aws_appautoscaling_policy" "memory_step_prd_test2" {
  name               = "${aws_ecs_service.prd_test2.name}-memory-utilization-step-scaling-policy"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.prd_test2.resource_id
  scalable_dimension = aws_appautoscaling_target.prd_test2.scalable_dimension
  service_namespace  = aws_appautoscaling_target.prd_test2.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "PercentChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"
    step_adjustment {
      metric_interval_lower_bound = 0
      metric_interval_upper_bound = 10
      scaling_adjustment          = 20
    }
    step_adjustment {
      metric_interval_lower_bound = 10
      scaling_adjustment          = 30
    }
  }
}

# 通常時はメモリ平均利用率を目標値に保つポリシー。
resource "aws_appautoscaling_policy" "memory_target_prd_test2" {
  name               = "${aws_ecs_service.prd_test2.name}-memory-utilization-target-scaling-policy"
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
