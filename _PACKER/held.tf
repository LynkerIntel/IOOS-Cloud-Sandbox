
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (replace with appropriate AMI for your region)
  instance_type = "t2.micro"
  
  iam_instance_profile = aws_iam_instance_profile.s3_access_profile.name
  
  tags = {
    Name = "${var.environment}-example-instance"
  }
}
resource "aws_iam_role" "s3_access_role" {
  name = "${var.environment}-s3-access-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "${var.environment}-s3-access-policy"
  description = "Policy that allows full access to the state bucket"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.state_bucket.arn,
          "${aws_s3_bucket.state_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  role       = aws_iam_role.s3_access_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_instance_profile" "s3_access_profile" {
  name = "${var.environment}-s3-access-profile"
  role = aws_iam_role.s3_access_role.name
}
