resource "aws_lb" "pricing_api" {
  name               = "alb-pricing-api-${var.name_suffix}"
  internal           = false
  load_balancer_type = "application"
  subnets            = [for subnet in aws_subnet.public : subnet.id]
  security_groups    = [aws_security_group.alb.id]

  access_logs {
    bucket  = "${var.access_logs_bucket}-${var.name_suffix}"
    prefix  = "alb"
    enabled = true
  }

  tags = {
    Name = "alb-pricing-api-${var.name_suffix}"
  }
}

resource "aws_lb_target_group" "pricing_api" {
  name        = "tg-pricing-api-${var.name_suffix}"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.pricing_api.id

  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "tg-pricing-api-${var.name_suffix}"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.pricing_api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pricing_api.arn
  }
}
