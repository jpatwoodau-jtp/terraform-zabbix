# Note: If deactivating child modules, must comment out related outputs here as well.

output "efs_id" {
  description = "EFS ID. Use for efs-provisioner in Kubernetes."
  value       = module.eks.efs_id
}

#output "vault_kms_id" {
#  description = "KMS ID. Use for Vault auto-unseal."
#  value       = module.eks.vault_kms_id
#}
