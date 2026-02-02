resource "aws_lb" "web_alb" {
  name               = "${var.project_name}-${var.environment}-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_ssm_parameter.web_alb_sg_id.value]
  subnets            = split(",", data.aws_ssm_parameter.public_subnet_ids.value) # this will select all private subnets from the comma-separated list
  enable_deletion_protection = false
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-web-alb"
    }
  )
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/html"
      message_body = "<h1>This is the default response for the WEB ALB</h1>"
      status_code  = "200"
  }
}
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 443
  protocol          = "TLS"
  certificate_arn = ""
  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/html"
      message_body = "<h1>This is the default response for the WEB ALB HTTPS</h1>"
      status_code  = "200"
  }
}
}

module "zone" {
  source = "terraform-aws-modules/route53/aws"
  create_zone = false # since zone already exists
  records = {
    alb = {
      zone_id = data.aws_route53_zone.existing.zone_id
      name    = "web-${var.environment}"
      type    = "A"
      allow_overwrite = true
      alias = {
        name                   = aws_lb.web_alb.dns_name
        zone_id                = aws_lb.web_alb.zone_id
      }
  }
}
}