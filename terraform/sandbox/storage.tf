

resource "aws_efs_file_system" "main_efs" {
  encrypted              = false
  availability_zone_name = var.availability_zone
  tags = {
    Name    = "${var.name_tag} EFS"
    Project = var.project_tag
  }
}


resource "aws_efs_mount_target" "mount_target_main_efs" {
  subnet_id       = local.subnet.id
  security_groups = [aws_security_group.efs_sg.id]
  file_system_id  = aws_efs_file_system.main_efs.id
}

