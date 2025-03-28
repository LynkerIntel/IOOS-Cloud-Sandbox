variable "profile" {
  description = "AWS profile to use"
  type        = string
  default     = "lcsb-admin"
}
variable "availability_zone" {
  description = "Availability zone to use"
  type        = string
  default     = "us-east-2b"
}

variable "region" {
  description = "Preferred region in which to launch EC2 instances. Defaults to us-east-2"
  type        = string
  default     = "us-east-2"
}

variable "nameprefix" {
  description = "Prefix to use for some resource names to avoid duplicates"
  type        = string
  default     = "lcsb_trial"
}

variable "environment" {
  description = "Environment to use for tagging"
  type        = string
  default     = "LCSB"
}

variable "owner" {
  description = "Owner to use for tagging"
  type        = string
  default     = "Mykel"
}

variable "name_tag" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "LCSB-Trial"
}

variable "project_tag" {
  description = "Value of the Project tag for the EC2 instance"
  type        = string
  default     = "LCSB-Trial"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t3.medium"

}

variable "use_efa" {
  description = "Attach EFA Network"
  type        = bool
  default     = "false"
}

variable "key_name" {
  description = "The name of the key-pair used to access the EC2 instances"
  type        = string
  default     = "trial"
}

#variable "allowed_ssh_cidr" {
#  description = "Public IP address/range allowed for SSH access"
#  type = string
#  nullable = false
#}

variable "allowed_ssh_cidr_list" {
  description = "Public IP address/range allowed for SSH access"
  type        = list(any)
  default     = ["0.0.0.0/0"]
}

variable "public_key" {
  description = "Contents of the SSH public key to be used for authentication"
  type        = string

  sensitive = true
  default   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM5SGDmS5HMtNkWkAR7rJNntiZKfCovuODF4MnpHlNoE mykel.alvis@Mykels-Mac-mini.local"
}

variable "managed_policies" {
  description = "The attached IAM policies granting machine permissions"
  default = ["arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  "arn:aws:iam::aws:policy/AmazonFSxFullAccess"]
}

variable "ami_id" {
  description = "The random ID used for AMI creation"
  type        = string
  default     = "unknown value"
}
