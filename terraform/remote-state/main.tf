provider "aws" {
  region  = var.region
}

resource "aws_s3_bucket" "terraform-state" {
  bucket = var.bucket
     
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_versioning" "terraform-state" {
    bucket = aws_s3_bucket.terraform-state.id

    versioning_configuration {
      status = "Enabled"
    }
}

# only needed for resource locking i.e. multiple developers
resource "aws_dynamodb_table" "terraform_state_lock" {
 name           = "${var.bucket}-lock"
 read_capacity  = 1
 write_capacity = 1
 hash_key       = "LockID"

 attribute {
   name = "LockID"
   type = "S"
 }
}
