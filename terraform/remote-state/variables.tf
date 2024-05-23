variable "region" {
  description = "Region in which to create the S3 bucket for Terraform state backend storage."
  type        = string
  nullable     = false
}

variable "bucket" {
  description = "Bucket name to use for Terraform state backend."
  type        = string
  nullable     = false
}
