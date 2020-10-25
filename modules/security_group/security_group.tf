variable name {
  type        = string
  description = "name of security group"
}

variable vpc_id {
    type = string
    description = "vpc id"
}

variable port {
  type        = number
  description = "ingress port number"
}

variable tag_name {
    type = string
    description = "name of tag"
}

variable ingress_cidr_blocks {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "cidr block for ingress"
}

resource "aws_security_group" "default" {
    name = var.name
    vpc_id = var.vpc_id

    ingress {
        from_port = var.port
        to_port = var.port
        protocol = "tcp"
        cidr_blocks = var.ingress_cidr_blocks
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = var.tag_name
    }
}

output "id" {
    value = aws_security_group.default.id
}