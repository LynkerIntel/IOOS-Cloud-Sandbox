data "aws_partition" "current" {}

data "aws_region" "current" {}

variable "ebs_root_vol_size" {
  type    = number
  default = 100
}

variable "aws_region" {
  type    = string
  default = "us-west-1"

}

variable "image_receipe_version" {
  type    = string
  default = "1.0.0"
}

variable "aws_s3_log_bucket" {
  type    = string
  default = "malvis-cloud-sandbox-tfstate"
}


resource "aws_security_group" "headnode" {
  vpc_id = var.vpc_id
  name   = "${var.nameprefix}-headnode-sg"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
    "0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
    "0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
    "0.0.0.0/0"]
  }

}

resource "aws_subnet" "headnode" {
  vpc_id     = var.vpc_id
  cidr_block = "10.0.0.0/24" # TODO 

}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# resource "aws_kms_key" "malviskey" {}

# resource "aws_kms_alias" "malviskey" {
#   name          = "alias/image-builder"
#   target_key_id = aws_kms_key.malviskey
# }


resource "aws_iam_role" "mykel" {
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
  inline_policy {
    name = "mykelpolicy"

    policy = jsonencode({
      "Version" = "2012-10-17",
      "Statement" = [
        {
          "Effect"   = "Allow"
          "Action"   = "*"
          "Resource" = "*"
        },
      ]
      }
    )
  }
}

variable "aws_key_pair_name" {
  type    = string
  default = "malvis@lynker.com-testingonly"
}

variable "ec2_iam_role_name" {
  type    = string
  default = ""
}