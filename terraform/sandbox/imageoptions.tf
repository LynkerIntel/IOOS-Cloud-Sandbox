
### AMI Options
### Specify aws_ami.*****.id in aws_instance section below

########################
# CentOS 7 CentOS AMI
# ami-033adaf0b583374d4
########################

data "aws_ami" "centos_7" {
  owners      = ["125523088429"] # CentOS.org
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7 *"]
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


########################
# CentOS 7 AMI by AWS

# 2023-04-17 us-east-2 id
# ami-05a36e1502605b4aa
########################

data "aws_ami" "centos_7_aws" {
  owners      = ["679593333241"] # AWS Marketplace
  most_recent = true

  filter {
    name   = "description"
    values = ["CentOS-7*"]
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
# Amazon Linux 2 AMI - untested
# ami-0b0f111b5dcb2800f  Amazon Linux 2 Kernel 5.10 AMI 2.0.20230404.1 x86_64 HVM gp2
# ami-02751969195641ff2  Amazon Linux 2 SELinux Enforcing AMI 2.0.20230404.1 x86_64 Minimal HVM gp2
###################################

data "aws_ami" "amazon_linux_2" {
  #owners = ["679593333241"]   # AWS Marketplace
  #owners = ["137112412989"]   # amazon
  owners      = ["amazon"] # AWS
  most_recent = true

  filter {
    name   = "description"
    values = ["Amazon Linux 2 Kernel 5.*"]
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
# Amazon Linux 2023 AMI - untested
##################################

# id us-east-2 2023-04-17 Description
# ----------------------- -----------
# ami-0103f211a154d64a6   "Amazon Linux 2023 AMI 2023.0.20230329.0 x86_64 HVM kernel-6.1"
# ami-00d80f7cbbd22eb22   "Amazon Linux 2023 AMI 2023.0.20230329.0 x86_64 Minimal HVM kernel-6.1"
###################################

data "aws_ami" "amazon_linux_2023" {
  #owners = ["679593333241"]   # AWS Marketplace
  #owners = ["137112412989"]   # amazon
  owners      = ["amazon"] # AWS
  most_recent = true

  filter {
    name   = "description"
    values = ["Amazon Linux 2023 * x86_64 HVM *"]
    # values = ["Amazon Linux 2023 * x86_64 Minimal HVM *"]
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


################################
# RedHat 8 UFS AMI - testing
################################

data "aws_ami" "rh_ufs" {
  owners      = ["309956199498"] # NOAA user
  most_recent = true

  filter {
    name   = "name"
    values = ["RHEL-8.4.*x86_64*"]
    #values = ["RHEL-8.2.0_HVM-20210907-x86_64-0-Hourly2-GP2"]  # openSSL yum issues
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
