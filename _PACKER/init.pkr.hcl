packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.6"
      source  = "github.com/hashicorp/amazon"

    }
  }
}


variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "aws_profile" {
  type    = string
  default = "lcsb-admin"
}

variable "instance_type" {
  type    = string
  default = "t3a.medium"
}

variable "ami_name_prefix" {
  type    = string
  default = "lcsb-cloud-sandbox"
}

variable "aws_vpc_id" {
  type    = string
  default = "vpc-07c82bc6865fb19fa"
}

variable "aws_subnet_id" {
  type    = string
  default = "subnet-0e6dca723adf8ce7f"
}

source "amazon-ebs" "almalinux" {
  ami_name      = "${var.ami_name_prefix}-{{timestamp}}"
  instance_type = var.instance_type
  region        = var.aws_region
  profile       = var.aws_profile
  vpc_id        = var.aws_vpc_id
  subnet_id     = var.aws_subnet_id

  source_ami_filter {
    filters = {
      name                = "AlmaLinux OS 9*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      architecture        = "x86_64"
    }
    most_recent = true
    owners      = ["764336703387"] # AlmaLinux Official Account
    # AlmaLinux OS 9.3.20240303 x86_64 is ami-0348aac978099b30a
  }

  ssh_username = "ec2-user"

  tags = {
    Name        = "${var.ami_name_prefix}"
    Environment = "development"
    Created     = "{{timestamp}}"
    Tool        = "Packer"
  }
}

build {
  name    = "lcsb-cloud-sandbox"
  sources = ["source.amazon-ebs.almalinux"]

  provisioner "shell" {
    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y git python3-pip"
    ]
  }
  provisioner "shell" {
  scripts = [
    "_SCRIPT_DEBUG/init_template.sh"
    ]
  }

  # Clean up
  provisioner "shell" {
    inline = [
      "sudo dnf clean all"
    ]
  }
}
