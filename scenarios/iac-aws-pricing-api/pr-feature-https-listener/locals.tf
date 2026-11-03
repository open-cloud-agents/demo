locals {
  availability_zones = ["eu-west-1a", "eu-west-1b"]

  public_cidr_block  = cidrsubnet(aws_vpc.pricing_api.cidr_block, 1, 0)
  private_cidr_block = cidrsubnet(aws_vpc.pricing_api.cidr_block, 1, 1)

  # One /24 per AZ out of each /23 tier. Widen the VPC CIDR before adding a third AZ.
  public_subnets = {
    for az in local.availability_zones :
    az => cidrsubnet(local.public_cidr_block, 1, index(local.availability_zones, az))
  }

  private_subnets = {
    for az in local.availability_zones :
    az => cidrsubnet(local.private_cidr_block, 1, index(local.availability_zones, az))
  }
}
