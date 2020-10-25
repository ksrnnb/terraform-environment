# AMIのデータ。ECS用に最適化されたもの
data "aws_ami" "ecs" {
  # most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-2.0.20201013-x86_64-ebs"]
  }
  owners = ["amazon"]
}

# launch configuration
resource "aws_launch_configuration" "ecs" {
  name_prefix   = "ecs-launch-tf-"
  image_id      = data.aws_ami.ecs.id
  instance_type = "t2.micro"

  security_groups      = [module.nginx_sg.id]
  enable_monitoring    = false // trueだとお金かかる
  iam_instance_profile = aws_iam_instance_profile.ec2_container_service.name
  user_data            = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${local.app_name}-cluster >> /etc/ecs/ecs.config;
EOF

  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }
}

# EC2がコンテナを利用できるように
data "aws_iam_policy" "ec2_container_service" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# ポリシードキュメント
data "aws_iam_policy_document" "ec2_container_service" {
  source_json = data.aws_iam_policy.ec2_container_service.policy
}

# ポリシーとロールのリソース作成
module "ec2_container_service" {
  source          = "./modules/iam_role"
  name            = "ec2_container_service"
  policy_document = data.aws_iam_policy_document.ec2_container_service.json
  identifiers     = ["ec2.amazonaws.com"]
}

resource "aws_iam_instance_profile" "ec2_container_service" {
  name = "es2_container_service"
  role = module.ec2_container_service.role.name
}


# auto scalingグループの設定
# この設定でEC2が立ち上がる。
resource "aws_autoscaling_group" "ecs" {
  name             = "ecs-tf-asg"
  min_size         = 1
  max_size         = 2
  desired_capacity = 2

  launch_configuration = aws_launch_configuration.ecs.name
  vpc_zone_identifier  = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]

  protect_from_scale_in = false

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, target_group_arns]
  }

  // 自動的に付与されるタグだけど、Terraformだと明記する必要あり。詳細はドキュメント参照。
  tags = [
    {
      key                 = "AmazonECSManaged"
      propagate_at_launch = true
    }
  ]
}

resource "aws_ecs_capacity_provider" "main" {
  name = "main"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }
  }
}