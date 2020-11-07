#vpc
resource "aws_vpc" "main" {
  cidr_block = "10.3.0.0/16"

  tags = {
    Name = "${local.app_name}-tf"
  }
}

# subnet
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.3.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "${local.app_name}-tf-public-1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.3.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1c"

  tags = {
    Name = "${local.app_name}-tf-public-1c"
  }
}

resource "aws_subnet" "private_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.3.65.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "ap-northeast-1a"
  tags = {
    Name = "${local.app_name}-tf-private-1a"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.3.66.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "ap-northeast-1c"

  tags = {
    Name = "${local.app_name}-tf-private-1c"
  }
}

# igw
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.app_name}-tf"
  }
}

# route table public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.app_name}-tf-public"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = [aws_route_table.public]
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

# route table private
resource "aws_route_table" "private_1a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.app_name}-tf-private_1a"
  }
}

resource "aws_route_table" "private_1c" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.app_name}-tf-private_1c"
  }
}

resource "aws_route" "private_1a" {
  route_table_id         = aws_route_table.private_1a.id
  instance_id            = aws_instance.nat.id
  destination_cidr_block = "0.0.0.0/0"
}

# NATインスタンスは現在1台（AZ: 1a）
resource "aws_route" "private_1c" {
  route_table_id         = aws_route_table.private_1c.id
  instance_id            = aws_instance.nat.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_1a.id
}

resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private_1c.id
}

# security group
module "http_sg" {
  source              = "./modules/security_group"
  name                = "http_sg"
  vpc_id              = aws_vpc.main.id
  port                = "80"
  ingress_cidr_blocks = ["0.0.0.0/0"]
  tag_name            = "http-tf"
}

module "https_sg" {
  source              = "./modules/security_group"
  name                = "https_sg"
  vpc_id              = aws_vpc.main.id
  port                = "443"
  ingress_cidr_blocks = ["0.0.0.0/0"]
  tag_name            = "https-tf"
}
