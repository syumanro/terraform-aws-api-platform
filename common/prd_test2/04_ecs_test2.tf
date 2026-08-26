# -----------------------------------------------------------------------------
# ECS Cluster
# Fargate タスクを実行するクラスター。Container Insights を有効化する。
# -----------------------------------------------------------------------------

# Fargate タスクを論理的にまとめ、Container Insights を有効化する単位。
resource "aws_ecs_cluster" "prd_test2" {
  name = "zhu-prd-ecs-test2-cluster"
  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "zhu-prd-ecs-test2-cluster"
  }
}

# 通常の Fargate と低コストな Fargate Spot を選択可能にする。
resource "aws_ecs_cluster_capacity_providers" "prd_test2" {
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  cluster_name       = aws_ecs_cluster.prd_test2.name
}

# -----------------------------------------------------------------------------
# ECS Service
# 2 つの ECS 用プライベートサブネットにタスクを配置し、ALB の 443 / 10443
# リスナールールが参照する 2 つのターゲットグループへ同じコンテナを登録する。
# -----------------------------------------------------------------------------

# desired_count を維持し、ALB と CodeDeploy が操作する長期稼働サービス。
resource "aws_ecs_service" "prd_test2" {
  cluster                            = aws_ecs_cluster.prd_test2.id
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  # 初回デプロイ時にも ALB のヘルスチェック対象を確保するため、最低 1 タスク起動する。
  desired_count                     = 1
  enable_ecs_managed_tags           = true
  enable_execute_command            = true
  health_check_grace_period_seconds = 0
  launch_type                       = "FARGATE"
  name                              = "zhu-prd-ecs-test2-service"
  platform_version                  = "1.4.0"
  propagate_tags                    = "SERVICE"
  scheduling_strategy               = "REPLICA"
  # 初回作成時は、この Terraform が作成するタスク定義を使用する。
  # 以後のリビジョン更新は CodeDeploy が行うため、lifecycle で差し戻しを防ぐ。
  task_definition = aws_ecs_task_definition.prd_test2.arn

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [
      load_balancer,
      # CodeDeploy や CI/CD がタスク定義を更新しても、Terraform で差し戻さない。
      task_definition,
      desired_count,
      launch_type,
      platform_version
    ]
  }

  load_balancer {
    container_name   = "zhu-prd-container-test2"
    container_port   = 80
    target_group_arn = aws_lb_target_group.tg01.arn
  }

  network_configuration {
    assign_public_ip = false
    subnets          = [aws_subnet.ecs_a.id, aws_subnet.ecs_c.id]
    security_groups  = [aws_security_group.ecs.id]

  }

  service_registries {
    registry_arn = aws_service_discovery_service.test2.arn
  }
  tags = {
    Name = "zhu-prd-ecs-test2-service"
  }

  depends_on = [
    aws_lb_listener.alb_443,
    aws_lb_listener_rule.prd_443,
  ]
}


# -----------------------------------------------------------------------------
# ECS Task Definition
# awsvpc ネットワークモードの Fargate タスク。コンテナの 80 番ポートを
# ALB の tg01 / tg02 から利用する。
# -----------------------------------------------------------------------------

# コンテナイメージ、CPU、メモリ、ネットワーク設定を再現可能なリビジョンとして定義する。
resource "aws_ecs_task_definition" "prd_test2" {
  container_definitions = jsonencode([{
    cpu         = 256
    environment = []
    essential   = true
    image       = "httpd:latest"

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/zhu-prd-ecs-test2"
        awslogs-region        = "ap-northeast-1"
        awslogs-stream-prefix = "ecs"
      }
    }
    memoryReservation = 512
    mountPoints = [{
      containerPath = "/"
      readOnly      = false
      sourceVolume  = "zhu-prd-test2-volume"
    }]
    name = "zhu-prd-container-test2"
    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]
    }
  ])
  cpu = 256
  # 既存の ECS Task Execution Role。ECR からの取得と CloudWatch Logs 出力に使用する。
  execution_role_arn       = "arn:aws:iam::043300555595:role/zhu-prd-ecs-task-execution-role"
  family                   = "zhu-prd-ecs-test2"
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  # 既存の ECS Task Role。アプリケーションコンテナへ付与する権限。
  task_role_arn = "arn:aws:iam::043300555595:role/zhu-prd-ecs-task-role"
  track_latest  = false
  runtime_platform {
    operating_system_family = "LINUX"
  }
  volume {
    name = "zhu-prd-test2-volume"
  }
  tags = {
    Name = "zhu-prd-ecs-test2-task-definition"
  }
}


# -----------------------------------------------------------------------------
# CloudWatch Logs
# コンテナ標準出力・標準エラー出力の保存先。
# -----------------------------------------------------------------------------

# タスクの標準出力・標準エラーを集中保存し、障害調査に利用する。
resource "aws_cloudwatch_log_group" "ecs_test2" {
  log_group_class   = "STANDARD"
  name              = "/ecs/zhu-prd-ecs-test2"
  retention_in_days = 1827

  tags = {
    Name = "zhu-prd-ecs-test2-logs"
  }
}

# -----------------------------------------------------------------------------
# Service Discovery (AWS Cloud Map)
# ECS タスクを VPC 内のプライベート DNS に自動登録する。
# 例: サービス名 test2、Namespace zhu-prd.local の場合は
#     test2.zhu-prd.local でタスクのプライベート IP を名前解決できる。
# -----------------------------------------------------------------------------

# VPC 内だけで解決できる名前空間を作成し、サービス間通信を DNS 化する。
resource "aws_service_discovery_private_dns_namespace" "test2" {
  name        = "zhu-prd.local"
  description = "Private DNS namespace for zhu-prd ECS services"
  vpc         = var.vpc_id

  tags = {
    Name = "zhu-prd-service-discovery"
  }
}

# ECS タスクの IP を Cloud Map に自動登録し、固定 IP なしで名前解決できるようにする。
resource "aws_service_discovery_service" "test2" {
  name = "test2"

  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.test2.id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 60
      type = "A"
    }
  }

  # ECS がタスク停止時に DNS レコードを削除できるようにする。
  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    Name = "zhu-prd-ecsservice-test2"
  }
}
