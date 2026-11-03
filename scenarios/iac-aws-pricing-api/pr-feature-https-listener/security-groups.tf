resource "aws_security_group" "alb" {
  name        = "secgroup-pricing-api-alb-${var.name_suffix}"
  description = "Public entry point for the pricing API load balancer"
  vpc_id      = aws_vpc.pricing_api.id

  tags = {
    Name = "secgroup-pricing-api-alb-${var.name_suffix}"
  }
}

resource "aws_security_group" "api_task" {
  name        = "secgroup-pricing-api-task-${var.name_suffix}"
  description = "Pricing API Fargate tasks"
  vpc_id      = aws_vpc.pricing_api.id

  tags = {
    Name = "secgroup-pricing-api-task-${var.name_suffix}"
  }
}

resource "aws_security_group" "database" {
  name        = "secgroup-pricing-api-db-${var.name_suffix}"
  description = "Pricing API PostgreSQL instance"
  vpc_id      = aws_vpc.pricing_api.id

  tags = {
    Name = "secgroup-pricing-api-db-${var.name_suffix}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_inbound_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_inbound_https" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_outbound_task" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.api_task.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080

  # AWS reports the referenced group back as "<account-id>/<sg-id>" while the
  # config supplies the bare id, so every refresh shows a spurious update. Pinned
  # until the provider normalises it.
  lifecycle {
    ignore_changes = [referenced_security_group_id]
  }
}

resource "aws_vpc_security_group_ingress_rule" "api_task_inbound_alb" {
  security_group_id            = aws_security_group.api_task.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080

  # AWS reports the referenced group back as "<account-id>/<sg-id>" while the
  # config supplies the bare id, so every refresh shows a spurious update. Pinned
  # until the provider normalises it.
  lifecycle {
    ignore_changes = [referenced_security_group_id]
  }
}

resource "aws_vpc_security_group_ingress_rule" "api_task_inbound_https" {
  security_group_id = aws_security_group.api_task.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "api_task_outbound_all" {
  security_group_id = aws_security_group.api_task.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "database_inbound_task" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.api_task.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432

  # AWS reports the referenced group back as "<account-id>/<sg-id>" while the
  # config supplies the bare id, so every refresh shows a spurious update. Pinned
  # until the provider normalises it.
  lifecycle {
    ignore_changes = [referenced_security_group_id]
  }
}