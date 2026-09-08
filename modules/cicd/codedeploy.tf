# ECS 用 Blue/Green デプロイを識別する CodeDeploy Application。
resource "aws_codedeploy_app" "prd_test2" {
  compute_platform = "ECS"
  name             = "AppECS-zhu-prd-ecs-test2-zhu-prd-ecsservice-test2"
}

# 2 つの TG と本番・テスト Listener を結び、無停止で新旧タスクを切り替える。
resource "aws_codedeploy_deployment_group" "prd_test2" {
  app_name                    = "AppECS-zhu-prd-ecs-test2-zhu-prd-ecsservice-test2"
  deployment_config_name      = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name       = "DgpECS-zhu-prd-ecs-test2-zhu-prd-ecsservice-test2"
  outdated_instances_strategy = "UPDATE"
  # 既存の CodeDeploy Service Role を使用する。
  service_role_arn = "arn:aws:iam::043300555595:role/zhu-prd-codedeploy-role"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      # テストトラフィックの確認後、手動承認なしで本番トラフィックを切り替える。
      action_on_timeout    = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 2800
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 2800
    }
  }
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  # デプロイ対象の ECS Cluster と ECS Service。
  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.ecs_service_name
  }

  # 443 は本番トラフィック、10443 は新バージョン確認用のテストトラフィック。
  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.production_listener_arn]
      }

      test_traffic_route {
        listener_arns = [var.test_listener_arn]
      }

      target_group {
        name = var.production_target_group_name
      }

      target_group {
        name = var.test_target_group_name
      }
    }
  }
  lifecycle {
    ignore_changes = [load_balancer_info]
  }
}
