# クラスターの定義
resource "aws_ecs_cluster" "main" {
  name               = "${local.app_name}-cluster"
  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 1
    base              = 1
  }
}

# サービス
resource "aws_ecs_service" "main" {
  name = "${local.app_name}-service"

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 1
    base              = 1
  }

  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.main.arn
  health_check_grace_period_seconds = 60

  desired_count                      = 2
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 50

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.nginx_sg.id]

    subnets = [
      aws_subnet.private_1a.id,
      aws_subnet.private_1c.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb.arn
    container_name   = "web"
    container_port   = 80
  }
}

# タスク定義
resource "aws_ecs_task_definition" "main" {
  family = "${local.app_name}-service"

  # タスク実行ロールはパラメータストアを利用するのに必要。
  execution_role_arn = module.ecs_task_execution.role.arn
  network_mode       = "awsvpc"

  container_definitions = file("./json/container_definitions.json")

  volume {
    name = "service-storage"
  }
}

# security group
module "nginx_sg" {
  source              = "./modules/security_group"
  name                = "nginx_sg"
  vpc_id              = aws_vpc.main.id
  port                = "80"
  ingress_cidr_blocks = [aws_vpc.main.cidr_block]
  tag_name            = "nginx_sg-tf"
}

# ECSのIAMポリシーのデータをとってくる
data "aws_iam_policy" "ecs_task_definition_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECSのIAMポリシーのデータを継承して、新たにパラメータストアの権限を追加する
data "aws_iam_policy_document" "ecs_task_execution" {
  source_json = data.aws_iam_policy.ecs_task_definition_role_policy.policy

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }
}

# ポリシーとロールのリソース作成
module "ecs_task_execution" {
  source          = "./modules/iam_role"
  name            = "ecs_task_execution"
  policy_document = data.aws_iam_policy_document.ecs_task_execution.json
  identifiers     = ["ecs-tasks.amazonaws.com"]
}