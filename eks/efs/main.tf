# EFS file system.
# aws_efs_file_system.efs_singapore
resource "aws_efs_file_system" "efs_singapore" {
  encrypted = "true"

  tags = {
    Name = "Terraformed-EFS"
  }
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

# Mount targets for each availability zone.
# aws_efs_mount_target.a
resource "aws_efs_mount_target" "a" {
  file_system_id  = aws_efs_file_system.efs_singapore.id
  subnet_id       = var.public_subnets[0]
  security_groups = [module.efs_mount_target_sg.this_security_group_id]
}

# aws_efs_mount_target.b
resource "aws_efs_mount_target" "b" {
  file_system_id  = aws_efs_file_system.efs_singapore.id
  subnet_id       = var.public_subnets[1]
  security_groups = [module.efs_mount_target_sg.this_security_group_id]
}

# aws_efs_mount_target.c
resource "aws_efs_mount_target" "c" {
  file_system_id  = aws_efs_file_system.efs_singapore.id
  subnet_id       = var.public_subnets[2]
  security_groups = [module.efs_mount_target_sg.this_security_group_id]
}

# Security group that allows worker nodes access to the mount targets.
# module.efs_mount_target_sg
module "efs_mount_target_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "3.4.0"
  name        = "efs-mount-target-sg"
  description = "sg for ec2 nodes to mount efs"
  vpc_id      = var.vpc_id
  ingress_with_source_security_group_id = [
    {
      rule                     = "nfs-tcp"
      source_security_group_id = var.source_security_group_id
      from_port                = 2049
      to_port                  = 2049
      protocol                 = "tcp"
      description              = "eks-efs nfs"
    },
  ]
}

