resource "aws_vpc" "cloud_vpc" {
  # we only will create this vpc if vpc_id is not passed in as a variable
  count = var.vpc_id != null ? 0 : 1
  # This is a large vpc, 256 x 256 IPs available
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name    = "${var.name_tag} VPC"
    Project = var.project_tag
  }
}


data "aws_vpc" "pre-provisioned" {
  # the pre-provisioned VPC will be returned if vpc_id matches an existing VPC
  count = var.vpc_id != null ? 1 : 0
  id    = var.vpc_id
}

resource "aws_subnet" "main" {
  count  = var.subnet_id != null ? 0 : 1
  vpc_id = local.vpc.id

  # If a subnet_cidr variable is passed explicitly, we use that,  
  # otherwise, divide the VPC by four and use 1/4 for a new subnet 
  cidr_block = var.subnet_cidr != null ? var.subnet_cidr : cidrsubnet(one(data.aws_vpc.pre-provisioned[*]).cidr_block, 2, var.subnet_quartile - 1)

  map_public_ip_on_launch = true

  availability_zone = var.availability_zone

  tags = {
    Name    = "${var.name_tag} Subnet"
    Project = var.project_tag
  }
}


data "aws_subnet" "pre-provisioned" {
  # the pre-provisioned Subnet will be returned if subnet_id matches an existing Subnet
  count = var.subnet_id != null ? 1 : 0
  id    = var.subnet_id
}

resource "aws_internet_gateway" "gw" {
  vpc_id = local.vpc.id
  tags = {
    Name    = "${var.name_tag} Internet Gateway"
    Project = var.project_tag
  }
}

resource "aws_route_table" "default" {
  vpc_id = local.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = one(aws_internet_gateway.gw[*].id)
  }
  tags = {
    Name    = "${var.name_tag} Route Table"
    Project = var.project_tag
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = one(aws_subnet.main[*].id)
  route_table_id = one(aws_route_table.default[*].id)
}
