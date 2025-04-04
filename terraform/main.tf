

data "terraform_remote_state" "bootstrap" {
  backend = "s3"
  config = {
    profile = "lcsb-admin"
    bucket  = "lcsb-terraform-state"
    key     = "tfstate/lcsb-bootstrap/terraform.tfstate"
    region  = "us-east-2"
  }
}

data "aws_availability_zone" "az" {
  name = var.availability_zone
}

data "aws_region" "region" {
  name = data.aws_availability_zone.az.region
}

locals {
  vpc_id      = data.terraform_remote_state.bootstrap.outputs.env_vpc_id
  subnet_id   = data.terraform_remote_state.bootstrap.outputs.public_subnets[var.availability_zone].id
  subnet_cidr = data.terraform_remote_state.bootstrap.outputs.public_subnets[var.availability_zone].cidr_block
}

data "aws_internet_gateway" "gw" {
  filter {
    name   = "attachment.vpc-id"
    values = [local.vpc_id]
  }
}

resource "aws_placement_group" "cloud_sandbox_placement_group" {
  name     = "${var.nameprefix}-${var.availability_zone}_Terraform_Placement_Group"
  strategy = "cluster"
  tags = {
    project = var.project_tag
  }
}

data "aws_vpc" "pre-provisioned" {
  # the pre-provisioned VPC will be returned if vpc_id matches an existing VPC
  id    = local.vpc_id
}

data "aws_subnet" "pre-provisioned" {
  id = local.subnet_id
}


resource "aws_efs_file_system" "main_efs" {
  encrypted              = false
  availability_zone_name = var.availability_zone
  tags = {
    Name    = "${var.name_tag}-${random_pet.ami_id.id} EFS"
    Project = var.project_tag
  }
}


resource "aws_efs_mount_target" "mount_target_main_efs" {
  subnet_id       = local.subnet_id
  security_groups = [aws_security_group.efs_sg.id]
  file_system_id  = aws_efs_file_system.main_efs.id
}


### AMI Options
### Specify aws_ami.*****.id in aws_instance section below


###################################
# RHEL 8
# 2023-10-06: ami-057094267c651958e
# AMI name: RHEL-8.7.0_HVM-20230330-x86_64-56-Hourly2-GP2
# Owner account ID 309956199498 Red Hat
##################################

data "aws_ami" "rhel_8" {

  #  owners = ["self"] # owners      = ["309956199498"]
  owners      = ["309956199498"]
  most_recent = true

  # filter {
  #   name   = "image-id"
  #   values = ["ami-029d4ac96b60510f3"]
  # }
  filter {
    name   = "name"
    values = ["RHEL-8.8*2025*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


###################################
# Centos Stream 9 - untested
# ami-0c2abda83f1b9e09d
# AMI name: CentOS Stream 9 x86_64 
# Owner account ID 125523088429
##################################

data "aws_ami" "centos_stream_9" {
  owners      = ["125523088429"] # CentOS Official CPE
  most_recent = true

  filter {
    name   = "description"
    values = ["CentOS Stream 9 *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# # Work around to get a public IP assigned when using EFA
# Removing this because we will always have a subnet_id
resource "aws_eip" "head_node" {
  instance = aws_instance.head_node.id
  tags = {
    Name    = "${var.name_tag}-${random_pet.ami_id.id} Elastic IP"
    Project = var.project_tag
  }
}


# efa enabled node
resource "aws_instance" "head_node" {

  #################################
  ### Specify which AMI to use here
  #############################################

  ami = data.aws_ami.rhel_8.id

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  instance_type = var.instance_type

  cpu_options {
    threads_per_core = 2
  }


  root_block_device {
    encrypted             = true
    delete_on_termination = true
    volume_size           = 16
    volume_type           = "gp3"
    tags = {
      Name    = "${var.name_tag}-${random_pet.ami_id.id} Head Root Volume"
      Project = var.project_tag
    }

  }

  depends_on = [

    data.aws_internet_gateway.gw,
    aws_efs_file_system.main_efs,
  aws_efs_mount_target.mount_target_main_efs]

  key_name             = var.key_name
  iam_instance_profile = data.terraform_remote_state.bootstrap.outputs.head_node_instance_profile

  user_data = templatefile("init_template.tpl",
    {
      efs_name   = aws_efs_file_system.main_efs.dns_name,
      ami_name   = "${var.name_tag}-${random_pet.ami_id.id}",
      aws_region = var.region, project = var.project_tag
    }
  )

  # associate_public_ip_address = true
  network_interface {
    network_interface_id = aws_network_interface.head_node.id
    device_index         = 0
  }

  # This logic isn't perfect since some ena instance types can be in a placement group also
  placement_group = var.use_efa == true ? aws_placement_group.cloud_sandbox_placement_group.id : null

  tags = {
    Name    = "${var.name_tag}-${random_pet.ami_id.id} Head"
    Project = var.project_tag
  }
}

# A random id to use when creating the AMI
# This needs a new id if the instance_id changes - otherwise it won't create a new AMI
resource "random_pet" "ami_id" {
  keepers = {
    #instance_id = aws_instance.head_node.id
    ami_id = var.ami_id
  }
  length = 2
}


# Can only attach efa adaptor to a stopped instance!
resource "aws_network_interface" "head_node" {

  subnet_id   = local.subnet_id
  description = "The network adaptor to attach to the head_node instance"
  security_groups = [aws_security_group.base_sg.id,
    aws_security_group.ssh_ingress.id,
  aws_security_group.efs_sg.id]

  interface_type = var.use_efa == true ? "efa" : null

  tags = {
    Name    = "${var.name_tag}-${random_pet.ami_id.id} Head Network Adapter"
    Project = var.project_tag
  }
}
# base sg
resource "aws_security_group" "base_sg" {
  vpc_id = local.vpc_id
  ingress {
    self      = true
    from_port = 0
    to_port   = 0
    protocol  = -1
  }
  egress {
    self      = true
    from_port = 0
    to_port   = 0
    protocol  = -1
  }
  tags = {
    Name    = "${var.name_tag}-${random_pet.ami_id.id} Base SG"
    Project = var.project_tag
  }
}

resource "aws_security_group" "efs_sg" {
  vpc_id = local.vpc_id
  ingress {
    self      = true
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
  }
  # allow all outgoing from NFS
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.name_tag}-${random_pet.ami_id.id} EFS SG"
    Project = var.project_tag
  }
}

resource "aws_security_group" "ssh_ingress" {
  vpc_id = local.vpc_id
  ingress {
    description = "Allow SSH from approved IP addresses"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_list
  }
  tags = {
    Name    = "${var.name_tag}-${random_pet.ami_id.id} SSH SG"
    Project = var.project_tag
  }
}
