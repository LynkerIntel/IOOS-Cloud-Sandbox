terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.24"
    }
  }
  backend "s3" {
    key = "tfstate"
  }
}

provider "aws" {
  region = var.preferred_region
}

data "aws_region" "current" {}
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

resource "random_pet" "ami_id" {
  keepers = {
    #instance_id = aws_instance.head_node.id
    ami_id = var.ami_id
  }
  length = 2
}

