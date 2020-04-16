output "vault_kms_id" {
  description = "KMS ID. Use for Vault auto-unseal."
  value       = aws_kms_key.vault.key_id
}
