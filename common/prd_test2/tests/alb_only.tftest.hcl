# All runs use a mocked provider and do not create AWS resources.
mock_provider "aws" {
  mock_resource "aws_lb" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:loadbalancer/app/test-alb/0123456789abcdef"
    }
  }

  mock_resource "aws_lb_target_group" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:targetgroup/test-target/0123456789abcdef"
    }
  }

  mock_resource "aws_lb_listener" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:listener/app/test-alb/0123456789abcdef/0123456789abcdef"
    }
  }
}

run "learning_ecs_egress_and_costs" {
  command = plan

  module {
    source = "../../modules/ecs"
  }

  variables {
    vpc_id            = "vpc-0123456789abcdef0"
    subnet_ids        = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
    security_group_id = "sg-0123456789abcdef0"
    target_group_arn  = "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:targetgroup/test-target/0123456789abcdef"
  }

  assert {
    condition = (
      one(aws_ecs_service.prd_test2.network_configuration).assign_public_ip &&
      one(aws_ecs_cluster.prd_test2.setting).value == "disabled" &&
      aws_cloudwatch_log_group.ecs_test2.retention_in_days == 7
    )
    error_message = "Learning tasks need public IP egress, disabled Container Insights and seven-day logs."
  }
}

run "public_and_private_networks" {
  command = apply

  module {
    source = "../../modules/network"
  }

  variables {
    vpc_id            = "vpc-0123456789abcdef0"
    ecs_a_subnet_cidr = "172.31.11.0/24"
    ecs_c_subnet_cidr = "172.31.12.0/24"
  }

  assert {
    condition = (
      aws_subnet.public_a.cidr_block == "172.31.21.0/24" &&
      aws_subnet.public_c.cidr_block == "172.31.22.0/24" &&
      aws_subnet.public_a.availability_zone != aws_subnet.public_c.availability_zone
    )
    error_message = "Public subnets must retain the existing CIDRs and span two availability zones."
  }

  assert {
    condition = (
      length(aws_route_table.public.route) == 1 &&
      one(aws_route_table.public.route).cidr_block == "0.0.0.0/0" &&
      length(aws_route_table.ecs_private.route) == 1 &&
      one(aws_route_table.ecs_private.route).gateway_id == aws_internet_gateway.main.id &&
      one(aws_route_table.ecs_private.route).cidr_block == "0.0.0.0/0" &&
      one(aws_route_table.public.route).gateway_id == aws_internet_gateway.main.id &&
      aws_route_table_association.public_a.route_table_id == aws_route_table.public.id &&
      aws_route_table_association.public_c.route_table_id == aws_route_table.public.id &&
      !aws_subnet.ecs_a.map_public_ip_on_launch &&
      !aws_subnet.ecs_c.map_public_ip_on_launch
    )
    error_message = "ALB and learning-mode ECS subnets need Internet Gateway routes."
  }
}

run "alb_security_boundary" {
  command = apply

  module {
    source = "../../modules/security_groups"
  }

  variables {
    vpc_id = "vpc-0123456789abcdef0"
  }

  assert {
    condition = (
      aws_vpc_security_group_ingress_rule.alb_443.cidr_ipv4 == "0.0.0.0/0" &&
      aws_vpc_security_group_ingress_rule.alb_443.from_port == 443 &&
      aws_vpc_security_group_ingress_rule.alb_10443.cidr_ipv4 == "0.0.0.0/0" &&
      aws_vpc_security_group_ingress_rule.alb_10443.from_port == 10443
    )
    error_message = "Production and test traffic must enter through the ALB listeners."
  }

  assert {
    condition = (
      aws_vpc_security_group_ingress_rule.ecs_from_alb.from_port == 80 &&
      aws_vpc_security_group_ingress_rule.ecs_from_alb.to_port == 80 &&
      aws_vpc_security_group_ingress_rule.ecs_from_alb.cidr_ipv4 == null &&
      aws_vpc_security_group_ingress_rule.ecs_from_alb.referenced_security_group_id == aws_security_group.alb.id &&
      aws_vpc_security_group_egress_rule.alb_to_ecs.from_port == 80 &&
      aws_vpc_security_group_egress_rule.alb_to_ecs.referenced_security_group_id == aws_security_group.ecs.id
    )
    error_message = "ECS must receive HTTP through the ALB security-group rule, without a public CIDR rule."
  }
}

run "public_alb_without_certificate" {
  command = apply

  module {
    source = "../../modules/load_balancing"
  }

  variables {
    vpc_id                = "vpc-0123456789abcdef0"
    alb_subnet_ids        = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
    alb_security_group_id = "sg-0123456789abcdef0"
  }

  assert {
    condition = (
      !aws_lb.alb.internal &&
      aws_lb.alb.load_balancer_type == "application" &&
      toset(aws_lb.alb.subnets) == toset(var.alb_subnet_ids)
    )
    error_message = "The ALB must be internet-facing and use the supplied public subnets."
  }

  assert {
    condition = (
      aws_lb_listener.alb_443.port == 443 &&
      aws_lb_listener.alb_10443.port == 10443 &&
      aws_lb_listener.alb_443.protocol == "HTTP" &&
      aws_lb_listener.alb_10443.protocol == "HTTP" &&
      aws_lb_target_group.tg01.target_type == "ip" &&
      aws_lb_target_group.tg02.target_type == "ip" &&
      aws_lb_target_group.tg01.name != aws_lb_target_group.tg02.name
    )
    error_message = "Certificate-free learning mode must retain both listeners and distinct Blue/Green IP target groups."
  }
}

run "public_alb_with_certificate" {
  command = apply

  module {
    source = "../../modules/load_balancing"
  }

  variables {
    vpc_id                = "vpc-0123456789abcdef0"
    alb_subnet_ids        = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
    alb_security_group_id = "sg-0123456789abcdef0"
    alb_certificate_arn   = "arn:aws:acm:ap-northeast-1:123456789012:certificate/01234567-89ab-cdef-0123-456789abcdef"
  }

  assert {
    condition = (
      aws_lb_listener.alb_443.protocol == "HTTPS" &&
      aws_lb_listener.alb_10443.protocol == "HTTPS" &&
      aws_lb_listener.alb_443.certificate_arn == var.alb_certificate_arn &&
      aws_lb_listener.alb_10443.certificate_arn == var.alb_certificate_arn
    )
    error_message = "Both listeners must use HTTPS and the supplied certificate when configured."
  }
}
