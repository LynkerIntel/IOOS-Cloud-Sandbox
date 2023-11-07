# efa enabled node
resource "aws_instance" "head_node" {
  # Base CentOS 7 AMI, can use either AWS's marketplace, or direct from CentOS
  # Choosing direct from CentOS as it is more recent


  #################################
  ### Specify which AMI to use here
  ### Only CentOS 7 has been thoroughly tested
  #############################################

  ami = data.aws_ami.centos_7.id
  # ami = data.aws_ami.centos_7_aws.id

  # Untested
  # ami = data.aws_ami.amazon_linux_2.id
  # ami = data.aws_ami.amazon_linux_2023.id

  # Can optionally use redhat - use the parameterized
  # ami = data.aws_ami.rh_ufs.id
  metadata_options {
    http_tokens = "required"
  }
  instance_type = var.instance_type
  cpu_options {
    core_count       = 4
    threads_per_core = 2
  }
  root_block_device {
    encrypted             = true
    delete_on_termination = true
    volume_size           = 12
  }

  depends_on = [aws_internet_gateway.gw,
    aws_efs_file_system.main_efs,
  aws_efs_mount_target.mount_target_main_efs]

  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.cloud_sandbox_iam_instance_profile.name
  user_data            = templatefile("init_templates/init_template.tpl", { efs_name = aws_efs_file_system.main_efs.dns_name, ami_name = "${var.name_tag}-${random_pet.ami_id.id}", aws_region = var.preferred_region, project = var.project_tag })

  # associate_public_ip_address = true
  network_interface {
    network_interface_id = aws_network_interface.head_node.id
    device_index         = 0
  }

  # This logic isn't perfect since some ena instance types can be in a placement group also
  placement_group = var.use_efa == true ? aws_placement_group.cloud_sandbox_placement_group.id : null

  tags = {
    Name    = "${var.name_tag} EC2 Head Node"
    Project = var.project_tag
  }
}

# A random id to use when creating the AMI
# This needs a new id if the instance_id changes - otherwise it won't create a new AMI
#data "template_file" "init_instance" {
#  template = file("./init_template.tpl")
#  vars = {
#    efs_name = aws_efs_file_system.main_efs.dns_name
#    ami_name = "${var.name_tag}-${random_pet.ami_id.id}"
#    aws_region = var.preferred_region
#    project = var.project_tag
#  }
#
#depends_on = [aws_efs_file_system.main_efs,
#              aws_efs_mount_target.mount_target_main_efs]
#}

# Can only attach efa adaptor to a stopped instance!
resource "aws_network_interface" "head_node" {

  subnet_id   = local.subnet.id
  description = "The network adaptor to attach to the head_node instance"
  security_groups = [aws_security_group.base_sg.id,
    aws_security_group.ssh_ingress.id,
  aws_security_group.efs_sg.id]

  interface_type = var.use_efa == true ? "efa" : null

  tags = {
    Name    = "${var.name_tag} Head Node Network Adapter"
    Project = var.project_tag
  }
}
