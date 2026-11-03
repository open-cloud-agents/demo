# ---------------------------------------------------------------------------
# Compute
#
# Fargate cluster, task definition and service for the pricing API. The tasks
# run in the public subnets and are only reachable through the load balancer.
#
# Nothing here is autoscaled yet - the desired count is fixed at two so that
# there is one task per availability zone.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Cluster
# ---------------------------------------------------------------------------

# The cluster is a logical grouping only - on Fargate there is no capacity to
# manage here.
resource "aws_ecs_cluster" "pricing_api" {
  name = "ecs-pricing-api-${var.name_suffix}"

  tags = {
    Name = "ecs-pricing-api-${var.name_suffix}"
  }
}

# ---------------------------------------------------------------------------
# Task definition
# ---------------------------------------------------------------------------

# Task definition for the single API container.
resource "aws_ecs_task_definition" "pricing_api" {
  # Revisions are grouped under this family name.
  family = "task-pricing-api-${var.name_suffix}"

  # Fargate sizing. 256/512 is the smallest valid combination and is ample for
  # the placeholder image.
  cpu    = 256
  memory = 512

  # Fargate requires awsvpc networking, which gives each task its own ENI.
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  # Pulls the container image and delivers logs on the task's behalf. This is
  # the execution role, not a task role - the container itself has no AWS
  # permissions of its own yet.
  execution_role_arn = aws_iam_role.task_execution.arn

  # Placeholder image while the real pricing API image is prepared in the
  # client's own ECR registry. Once that is ready only the image reference
  # below needs to change.
  container_definitions = jsonencode([
    {
      name      = "pricing-api"
      image     = "public.ecr.aws/nginx/nginx:stable"
      essential = true

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        },
      ]
    },
  ])

  tags = {
    Name = "task-pricing-api-${var.name_suffix}"
  }
}

# ---------------------------------------------------------------------------
# Service
# ---------------------------------------------------------------------------

# The service keeps two copies of the task running behind the target group.
resource "aws_ecs_service" "pricing_api" {
  name    = "ecs-svc-pricing-api-${var.name_suffix}"
  cluster = aws_ecs_cluster.pricing_api.id

  # Pinned to the latest revision of the task definition above.
  task_definition = aws_ecs_task_definition.pricing_api.arn

  # One task per availability zone.
  desired_count = 2
  launch_type   = "FARGATE"

  # Tasks sit in the public subnets and take a public IP so they can reach
  # ECR; inbound traffic is constrained by the task security group.
  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.api_task.id]
    subnets          = [for subnet in aws_subnet.public : subnet.id]
  }

  # Registers the task ENIs with the target group the listener forwards to.
  # The container name has to match the name used in the task definition.
  load_balancer {
    container_name   = "pricing-api"
    container_port   = 8080
    target_group_arn = aws_lb_target_group.pricing_api.arn
  }

  # The listener has to exist before the service can register any targets,
  # otherwise the first create races the load balancer.
  depends_on = [aws_lb_listener.http]

  tags = {
    Name = "ecs-svc-pricing-api-${var.name_suffix}"
  }
}
