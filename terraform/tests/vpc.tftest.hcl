# VPC Module Tests

run "vpc_configuration" {
  command = plan

  assert {
    condition     = length(aws_vpc.main) > 0
    error_message = "VPC must be created"
  }

  assert {
    condition     = aws_vpc.main[0].cidr_block == var.vpc_cidr
    error_message = "VPC CIDR must match variable"
  }

  assert {
    condition     = aws_vpc.main[0].enable_dns_hostnames == true
    error_message = "DNS hostnames must be enabled for EKS"
  }

  assert {
    condition     = aws_vpc.main[0].enable_dns_support == true
    error_message = "DNS support must be enabled"
  }
}

run "subnet_configuration" {
  command = plan

  assert {
    condition     = length(aws_subnet.public) >= 2
    error_message = "At least 2 public subnets required for ALB"
  }

  assert {
    condition     = length(aws_subnet.private) >= 2
    error_message = "At least 2 private subnets required for EKS"
  }
}

run "nat_gateway" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.main) > 0
    error_message = "NAT Gateway required for private subnet internet access"
  }

  assert {
    condition     = length(aws_eip.nat) > 0
    error_message = "Elastic IP required for NAT Gateway"
  }
}

run "internet_gateway" {
  command = plan

  assert {
    condition     = length(aws_internet_gateway.main) > 0
    error_message = "Internet Gateway required for public subnets"
  }
}

run "route_tables" {
  command = plan

  assert {
    condition     = length(aws_route_table.public) > 0
    error_message = "Public route table must exist"
  }

  assert {
    condition     = length(aws_route_table.private) > 0
    error_message = "Private route table must exist"
  }
}
