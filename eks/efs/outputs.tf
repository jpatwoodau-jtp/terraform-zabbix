output "efs_id" {
  description = "EFS ID. Use for efs-provisioner in Kubernetes."
  value       = aws_efs_file_system.efs_singapore.id
}

