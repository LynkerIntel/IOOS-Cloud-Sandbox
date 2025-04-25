terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.9"
    }
  }
  backend "s3" {
    profile        = var.profile
    bucket         = "csb-terraform-state"
    key            = "tfstate/trial/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "csb-terraform-state-lock"
  }

}

provider "aws" {
  region  = var.region
  profile = var.profile
  default_tags {
    tags = {
      Environment = var.environment
      Owner       = var.owner
      Project     = var.project_tag
    }
  }
}
