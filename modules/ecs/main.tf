# ECS cluster
resource "aws_ecs_cluster" "prd_test2" {

  name = "zhu-prd-ecs-test2-cluster"

  configuration {

    execute_command_configuration {

      logging = "DEFAULT"

    }

  }

  setting {

    name = "containerInsights"

    value = "enabled"

  }

  tags = {

    Name = "zhu-prd-ecs-test2-cluster"

  }

}

# Capacity providers
resource "aws_ecs_cluster_capacity_providers" "prd_test2" {

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  cluster_name = aws_ecs_cluster.prd_test2.name

}

# ECS service
resource "aws_ecs_service" "prd_test2" {

  cluster = aws_ecs_cluster.prd_test2.id

  deployment_maximum_percent = 200

  deployment_minimum_healthy_percent = 100

  desired_count = 1

  enable_ecs_managed_tags = true

  enable_execute_command = true

  health_check_grace_period_seconds = 0

  launch_type = "FARGATE"

  name = "zhu-prd-ecs-test2-service"

  platform_version = "1.4.0"

  propagate_tags = "SERVICE"

  scheduling_strategy = "REPLICA"

  task_definition = aws_ecs_task_definition.prd_test2.arn

  deployment_controller {

    type = "CODE_DEPLOY"

  }

  lifecycle {

    ignore_changes = [

      load_balancer,

      task_definition,

      desired_count,

      launch_type,

      platform_version

    ]

  }

  load_balancer {

    container_name = "zhu-prd-container-test2"

    container_port = 80

    target_group_arn = var.target_group_arn

  }

  network_configuration {

    assign_public_ip = false

    subnets = var.subnet_ids

    security_groups = [var.security_group_id]

  }

  service_registries {

    registry_arn = aws_service_discovery_service.test2.arn

  }

  tags = {

    Name = "zhu-prd-ecs-test2-service"

  }

}

# Task definition
resource "aws_ecs_task_definition" "prd_test2" {

  container_definitions = jsonencode([{

    cpu = 256

    environment = []

    essential = true

    image = "httpd:latest"

    logConfiguration = {

      logDriver = "awslogs"

      options = {

        awslogs-group = "/ecs/zhu-prd-ecs-test2"

        awslogs-region = "ap-northeast-1"

        awslogs-stream-prefix = "ecs"

      }

    }

    memoryReservation = 512

    mountPoints = [{

      containerPath = "/"

      readOnly = false

      sourceVolume = "zhu-prd-test2-volume"

    }]

    name = "zhu-prd-container-test2"

    portMappings = [{

      containerPort = 80

      hostPort = 80

      protocol = "tcp"

    }]

    }

  ])

  cpu = 256

  execution_role_arn = "arn:aws:iam::043300555595:role/zhu-prd-ecs-task-execution-role"

  family = "zhu-prd-ecs-test2"

  memory = 512

  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]

  task_role_arn = "arn:aws:iam::043300555595:role/zhu-prd-ecs-task-role"

  track_latest = false

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

# Container logs
resource "aws_cloudwatch_log_group" "ecs_test2" {

  log_group_class = "STANDARD"

  name = "/ecs/zhu-prd-ecs-test2"

  retention_in_days = 1827

  tags = {

    Name = "zhu-prd-ecs-test2-logs"

  }

}

# Service discovery
resource "aws_service_discovery_private_dns_namespace" "test2" {

  name = "zhu-prd.local"

  description = "Private DNS namespace for zhu-prd ECS services"

  vpc = var.vpc_id

  tags = {

    Name = "zhu-prd-service-discovery"

  }

}

resource "aws_service_discovery_service" "test2" {

  name = "test2"

  dns_config {

    namespace_id = aws_service_discovery_private_dns_namespace.test2.id

    routing_policy = "MULTIVALUE"

    dns_records {

      ttl = 60

      type = "A"

    }

  }

  health_check_custom_config {

    failure_threshold = 1

  }

  tags = {

    Name = "zhu-prd-ecsservice-test2"

  }

}
