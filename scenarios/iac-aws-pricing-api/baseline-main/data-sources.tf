data "aws_elb_service_account" "access_logs" {}

data "aws_iam_policy_document" "access_logs" {
  statement {
    sid     = "AllowLoadBalancerLogDelivery"
    effect  = "Allow"
    actions = ["s3:PutObject"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_elb_service_account.access_logs.id}:root"]
    }

    resources = ["${aws_s3_bucket.access_logs.arn}/alb/*"]
  }
}

data "aws_iam_policy_document" "task_execution_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
