# RDS instance
resource "aws_db_instance" "main" {
  identifier        = "${local.app_name}-tf"
  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "mysql"
  engine_version    = "8.0.21"
  instance_class    = "db.t2.micro"
  username          = "root"
  # passwordはあとで変更する必要あり！
  password                   = "password"
  multi_az                   = false
  publicly_accessible        = false
  backup_window              = "05:00-05:30"
  backup_retention_period    = 30
  maintenance_window         = "mon:06:00-mon:06:30"
  auto_minor_version_upgrade = false
  deletion_protection        = true
  skip_final_snapshot        = true
  port                       = 3306
  apply_immediately          = true
  vpc_security_group_ids     = [module.mysql_sg.id]
  parameter_group_name       = aws_db_parameter_group.main.name
  option_group_name          = aws_db_option_group.main.name
  db_subnet_group_name       = aws_db_subnet_group.main.name
}

# security group for rds
module "mysql_sg" {
  source              = "./modules/security_group"
  name                = "mysql-sg"
  vpc_id              = aws_vpc.main.id
  port                = 3306
  ingress_cidr_blocks = [aws_vpc.main.cidr_block]
  tag_name            = "${local.app_name}-mysql-sg"
}

# parameter group
resource "aws_db_parameter_group" "main" {
  name   = "${local.app_name}-tf-mysql80"
  family = "mysql8.0"

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
}

# option group
resource "aws_db_option_group" "main" {
  name                     = "${local.app_name}-tf-mysql80"
  option_group_description = "${local.app_name} option group"
  engine_name              = "mysql"
  major_engine_version     = "8.0"
}

# subnet group
resource "aws_db_subnet_group" "main" {
  name       = "${local.app_name}-tf"
  subnet_ids = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]
}