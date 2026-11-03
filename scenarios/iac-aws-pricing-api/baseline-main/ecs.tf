resource "aws_ecs_cluster" "pricing_api" {
  name = "ecs-pricing-api-${var.name_suffix}"

  tags = {
    Name = "ecs-pricing-api-${var.name_suffix}"
  }
}

resource "aws_ecs_task_definition" "pricing_api" {
  family                   = "task-pricing-api-${var.name_suffix}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution.arn

  # Placeholder image until the pricing API lands in the client's own ECR registry.
  container_definitions = jsonencode([
    {
      name         = "pricing-api"
      image        = "public.ecr.aws/nginx/nginx:stable"
      essential    = true
      portMappings = [{ containerPort = 8080, protocol = "tcp" }]
    }
  ])

  tags = {
    Name = "task-pricing-api-${var.name_suffix}"
  }
}

resource "aws_ecs_service" "pricing_api" {
  name            = "ecs-svc-pricing-api-${var.name_suffix}"
  cluster         = aws_ecs_cluster.pricing_api.id
  task_definition = aws_ecs_task_definition.pricing_api.arn
  launch_type     = "FARGATE"
  desired_count   = 2

  network_configuration {
    subnets          = [for subnet in aws_subnet.public : subnet.id]
    security_groups  = [aws_security_group.api_task.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.pricing_api.arn
    container_name   = "pricing-api"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http]

  tags = {
    Name = "ecs-svc-pricing-api-${var.name_suffix}"
  }
}
