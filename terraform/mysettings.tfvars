# Spefify this file when running terraform.

# Examples:
# terraform plan -var-file="mysettings.tfvars"
# terraform apply -var-file="mysettings.tfvars"
# terraform destroy -var-file="mysettings.tfvars"

#------------------------------------------------------------
# The following variables must be defined, no default exists:
#------------------------------------------------------------

# (This should be the public IPv4 address of your workstation for SSH acceess)
# This should be in the format ###.###.###.###/32
# Example: 72.245.67.89/32

allowed_ssh_cidr = "107.146.152.166/32"

# Specify the SSL key below.

# Example:
# key_name = "ioos-sandbox"
# public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2cQ3fzP1R2uQJcCd3g2ylW5clzyjun6eWz2PZKMwtJh7E28B1jp3F8YTP5XBPg0ouvZO6gkcrbgjhuM0A4NKJM6RylGAOqqPYnIbhd9eI3RKhSQbxsghjf5hwS7tIG1FebO9HuObaM23LDB1/Ra/YMTXB5LHPChlfxrEIlM/7OUfRPNgtudAb/MQZ+YD+6I77QDtTwZwQvebxLK62bP5CrpV4XY5ybWOZ0T3m4pVNfhfl7+QWAvWeStNpH3B3q1ZtPLTuAVvsR4RWk7t75IwpHwiPBcgZn/PTpN45z"

key_name   = "~/.ssh/lynker.pem" # the filename of the private SSL key 
public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIECgrptU05TnzjqBSTH9l9OECqg1tJrZOBry9Ma10nAA" # the matching public key (ssh-keygen -y -f your-key-pair.pem) 


# Example: 
# vpc_id = "vpc-0381e9f82c9ae68e7"
vpc_id = "vpc-06a68e7393505792f" 		# the ID of an existing VPC to deploy resources to


# Example: 
# subnet_id = "subnet-01ce99f9006e8ed06"
# subnet_id = "subnet-03b59bee407fcd506"		# the ID of an existing Subnet within the VPC to deploy resources to

subnet_cidr = "10.0.0.0/20"

#------------------------------------------------------------


#---------------------------------------------------------------
# Optionally uncomment and change these to override the defaults
#---------------------------------------------------------------

preferred_region = "us-west-1"
name_tag = "IOOS-Cloud-Sandbox-Terraform-mavis"
availability_zone = "us-west-1a"
project_tag = "IOOS-Cloud-Sandbox-malvis"
instance_type = "t3.medium"
# use_efa = false 

# You can give your AWS resources a unique name to avoid conflicts
# with other deployed sandboxes

nameprefix="malvis-sandbox"
#---------------------------------------------------------------

ec2_iam_role_name = "mykel"