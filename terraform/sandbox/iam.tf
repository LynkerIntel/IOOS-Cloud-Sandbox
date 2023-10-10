
resource "aws_iam_role" "sandbox_iam_assumerole_role" {
  name = "${var.nameprefix}_sandbox_assumerole_role"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          },
          "Effect" : "Allow",
          "Sid" : ""
        }
      ]
  })
  tags = {
    Name    = "${var.name_tag} IAM Role"
    Project = var.project_tag
  }
}

resource "aws_iam_role_policy_attachment" "sandbox_role_policy_attach" {
  count      = length(var.managed_policies)
  policy_arn = element(var.managed_policies, count.index)
  role       = aws_iam_role.sandbox_iam_assumerole_role.name
}

resource "aws_iam_instance_profile" "cloud_sandbox_iam_instance_profile" {
  name = "${var.nameprefix}_instance_profile_role"
  role = aws_iam_role.sandbox_iam_assumerole_role.name
}
