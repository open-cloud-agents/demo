output "ids" {
  value = {
    alb = {
      dns_name = aws_lb.pricing_api.dns_name
      arn      = aws_lb.pricing_api.arn
    }
    vpc             = aws_vpc.pricing_api.id
    public_subnets  = { for az, subnet in aws_subnet.public : az => subnet.id }
    private_subnets = { for az, subnet in aws_subnet.private : az => subnet.id }
    database = {
      endpoint   = aws_db_instance.api.endpoint
      identifier = aws_db_instance.api.identifier
    }
    ecs = {
      cluster = aws_ecs_cluster.pricing_api.arn
    }
  }
}
