# alb
resource "aws_lb" "main" {
  name               = "alb-${local.app_name}-tf"
  load_balancer_type = "application"
  internal           = false
  subnets = [
    aws_subnet.public_1a.id,
    aws_subnet.public_1c.id,
  ]

  security_groups = [
    module.http_sg.id,
    module.https_sg.id,
  ]
}

# target group
resource "aws_lb_target_group" "alb" {
  name                 = "${local.app_name}-tg-tf"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  target_type          = "ip"
  deregistration_delay = "10"

  # スティッキーセッション
  stickiness {
    enabled = true
    type = "lb_cookie"
    cookie_duration = 86400 // 1 day
  }

  depends_on = [aws_lb.main]
}

# alb listener from http to https
resource "aws_lb_listener" "http_redirect_to_https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# alb listener https
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb.arn
  }
}

# route53 data
data "aws_route53_zone" "main" {
  name = "${local.app_name}.jp"
}

# route53 A record to alb
resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = data.aws_route53_zone.main.name
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# route53 for certification
resource "aws_route53_record" "cert" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# ACM certification
resource "aws_acm_certificate" "main" {
  domain_name               = data.aws_route53_zone.main.name
  subject_alternative_names = []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# ACM validation
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert : record.fqdn]
}