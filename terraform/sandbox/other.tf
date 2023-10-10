
resource "aws_placement_group" "cloud_sandbox_placement_group" {
  name     = "${var.nameprefix}_Terraform_Placement_Group"
  strategy = "cluster"
  tags = {
    project = var.project_tag
  }
}


# here we assign local variables for both the VPC and the Subnet we'll need to refer to to deploy further resources below:
# use of the one() function is needed to ensure only a single value is assigned, rather than a tuple/set
locals {
  vpc    = var.vpc_id != null ? one(data.aws_vpc.pre-provisioned[*]) : one(aws_vpc.cloud_vpc[*])
  subnet = var.subnet_id != null ? one(data.aws_subnet.pre-provisioned[*]) : one(aws_subnet.main[*])

}

# Work around to get a public IP assigned when using EFA
resource "aws_eip" "head_node" {
  depends_on = [aws_internet_gateway.gw]
  domain     = "vpc"
  instance   = aws_instance.head_node.id
  tags = {
    Name    = "${var.name_tag} Elastic IP"
    Project = var.project_tag
  }
}

