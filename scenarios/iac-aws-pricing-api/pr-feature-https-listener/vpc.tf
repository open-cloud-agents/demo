# ---------------------------------------------------------------------------
# Networking
#
# A single VPC split into a public tier (the ALB and the Fargate tasks) and a
# private tier (the database only). All of the CIDR maths lives in locals.tf
# so the tiers stay derived from the VPC block rather than hard-coded here.
#
# Layout, for reference:
#
#   10.20.0.0/22   VPC
#     10.20.0.0/23 public tier   -> one /24 per availability zone
#     10.20.2.0/23 private tier  -> one /24 per availability zone
#
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------

resource "aws_vpc" "pricing_api" {
  # /22 leaves room for a third availability zone per tier later on.
  cidr_block = "10.20.0.0/22"

  # Enabled so that the RDS endpoint resolves from inside the VPC.
  enable_dns_hostnames = true

  # Naming follows the <type>-<service> convention used across the estate.
  tags = {
    Name = "vpc-pricing-api-${var.name_suffix}"
  }
}

# ---------------------------------------------------------------------------
# Subnets
#
# Both tiers are driven by the maps in locals.tf, so adding an availability
# zone there adds a subnet in each tier.
# ---------------------------------------------------------------------------

# Public subnets host the ALB and the Fargate tasks, one subnet per
# availability zone.
resource "aws_subnet" "public" {
  # Keyed by availability zone, values are the /24 CIDRs.
  for_each = local.public_subnets

  availability_zone = each.key
  cidr_block        = each.value
  vpc_id            = aws_vpc.pricing_api.id

  # Needed for egress: without a NAT gateway in this account the tasks reach
  # ECR and Secrets Manager directly over the internet gateway.
  map_public_ip_on_launch = true

  # Availability zone is included in the name so the subnets are easy to tell
  # apart in the console.
  tags = {
    Name = "subnet-pricing-api-public-${each.key}-${var.name_suffix}"
  }
}

# Private subnets carry the database only. There is deliberately no NAT
# gateway, so nothing placed in this tier has outbound internet access.
resource "aws_subnet" "private" {
  # Keyed by availability zone, values are the /24 CIDRs.
  for_each = local.private_subnets

  availability_zone = each.key
  cidr_block        = each.value
  vpc_id            = aws_vpc.pricing_api.id

  # No map_public_ip_on_launch here: instances in this tier stay private.
  tags = {
    Name = "subnet-pricing-api-private-${each.key}-${var.name_suffix}"
  }
}

# ---------------------------------------------------------------------------
# Internet edge
# ---------------------------------------------------------------------------

# Single internet gateway, shared by every public subnet.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.pricing_api.id

  tags = {
    Name = "igw-pricing-api-${var.name_suffix}"
  }
}

# ---------------------------------------------------------------------------
# Routing
#
# The private tier has no route table of its own and therefore falls back to
# the VPC main route table, which has no internet route.
# ---------------------------------------------------------------------------

# One route table shared by the whole public tier; the default route below
# points it at the internet gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.pricing_api.id

  tags = {
    Name = "rt-pricing-api-public-${var.name_suffix}"
  }
}

# Default route for the public tier.
resource "aws_route" "public_internet" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  route_table_id         = aws_route_table.public.id
}

# Attach every public subnet to the public route table. Iterating over the
# subnet resource rather than the locals map keeps this in step with
# local.public_subnets automatically.
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}
