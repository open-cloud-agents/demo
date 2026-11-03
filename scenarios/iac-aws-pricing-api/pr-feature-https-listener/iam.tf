resource "aws_iam_role" "task_execution" {
  name               = "role-pricing-api-task-execution-${var.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.task_execution_assume_role.json

  # Every role in this account carries the account's permissions boundary.
  permissions_boundary = var.permissions_boundary_arn

  tags = {
    Name = "role-pricing-api-task-execution-${var.name_suffix}"
  }
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
