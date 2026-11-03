resource "aws_vpc" "pricing_api" {
  cidr_block           = "10.20.0.0/22"
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-pricing-api-${var.name_suffix}"
  }
}

resource "aws_subnet" "public" {
  for_each                = local.public_subnets
  vpc_id                  = aws_vpc.pricing_api.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-pricing-api-public-${each.key}-${var.name_suffix}"
  }
}

# Private subnets carry the database only - there is no NAT gateway in this account.
resource "aws_subnet" "private" {
  for_each          = local.private_subnets
  vpc_id            = aws_vpc.pricing_api.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name = "subnet-pricing-api-private-${each.key}-${var.name_suffix}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.pricing_api.id

  tags = {
    Name = "igw-pricing-api-${var.name_suffix}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.pricing_api.id

  tags = {
    Name = "rt-pricing-api-public-${var.name_suffix}"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
