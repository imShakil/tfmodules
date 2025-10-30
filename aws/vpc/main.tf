# Data Sources
data "aws_availability_zones" "available" {
  state = "available"
}

# Set Subnets CIDR blocks
locals {
  # Auto-generate subnets if not provided
  public_subnets = length(var.public_subnets) > 0 ? var.public_subnets : [
    for i in range(var.subnet_size) : cidrsubnet(var.cidr_block, 8, i)
  ]

  private_subnets = length(var.private_subnets) > 0 ? var.private_subnets : [
    for i in range(var.subnet_size) : cidrsubnet(var.cidr_block, 8, i + 128)
  ]
}

# VPC
resource "aws_vpc" "myVPC" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.prefix}-vpc"
    Environment = terraform.workspace
  }
}

# Internet Gateway
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name        = "${var.prefix}-igw"
    Environment = terraform.workspace
  }
}

# Route Tables
resource "aws_route_table" "myPublicRT" {
  vpc_id = aws_vpc.myVPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name        = "${var.prefix}-publicRT"
    Environment = terraform.workspace
  }
}

resource "aws_route_table" "privateRT" {
  count  = length(local.private_subnets)
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name        = "${var.prefix}-privateRT-${count.index + 1}"
    Environment = terraform.workspace
  }
}

# Security Group
resource "aws_security_group" "mySG" {
  vpc_id      = aws_vpc.myVPC.id
  name        = "${var.prefix}-sg"
  description = "Security group for ${var.prefix}-vpc"

  tags = {
    Name        = "${var.prefix}-sg"
    Environment = terraform.workspace
  }
}

# Security Group Rules
resource "aws_vpc_security_group_ingress_rule" "allows_ssh" {
  security_group_id = aws_security_group.mySG.id
  description       = "Allows SSH"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allows_http" {
  security_group_id = aws_security_group.mySG.id
  description       = "Allows HTTP"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allows_https" {
  security_group_id = aws_security_group.mySG.id
  description       = "Allows HTTPS"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allows_vpc_internal" {
  security_group_id = aws_security_group.mySG.id
  description       = "Allows VPC internal communication"
  cidr_ipv4         = var.cidr_block
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allows_all" {
  security_group_id = aws_security_group.mySG.id
  description       = "Allows all outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Subnets
resource "aws_subnet" "public_subnet" {
  count                   = length(local.public_subnets)
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = local.public_subnets[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = {
    Name = "${var.prefix}-public_subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnet" {
  count                   = length(local.private_subnets)
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = local.private_subnets[count.index]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = {
    Name = "${var.prefix}-private_subnet-${count.index + 1}"
  }
}

# Route Table Associations
resource "aws_route_table_association" "publicRTAssociate" {
  count          = length(local.public_subnets)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.myPublicRT.id
}

resource "aws_route_table_association" "privateRTAssociate" {
  count          = length(local.private_subnets)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.privateRT[count.index].id
}
