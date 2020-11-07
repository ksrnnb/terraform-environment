# AMIのデータ。NAT
data "aws_ami" "nat" {
  # most_recent = true
  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat-2018.03.0.20200918.0-x86_64-ebs"]
  }
  owners = ["amazon"]
}

resource "aws_instance" "nat" {
  ami           = data.aws_ami.nat.id
  instance_type = "t2.nano"

  subnet_id       = aws_subnet.public_1a.id
  security_groups = [aws_security_group.nat.id]

  # NATの場合はこれが大事。
  # https://docs.aws.amazon.com/ja_jp/vpc/latest/userguide/VPC_NAT_Instance.html#EIP_Disable_SrcDestCheck
  source_dest_check = false

  tags = {
    Name = "nat-intance-tf"
  }
}

resource "aws_security_group" "nat" {
  name   = "nat-sg-tf"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "nat-sg-tf"
  }
}

resource "aws_security_group_rule" "in_private_1a_443" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [aws_subnet.private_1a.cidr_block]
  security_group_id = aws_security_group.nat.id
}

resource "aws_security_group_rule" "in_private_1c_443" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [aws_subnet.private_1c.cidr_block]
  security_group_id = aws_security_group.nat.id
}

resource "aws_security_group_rule" "out_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nat.id
}