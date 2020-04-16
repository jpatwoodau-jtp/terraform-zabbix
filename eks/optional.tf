# EFS module deploys EFS file system and mount targets. Mount targets' security group allows mounting from worker node SG.
# Note: If deactivating, must also comment out output "efs_id" in parent module.

module "efs" {
  source = "./efs"

  source_security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id

  vpc_id = module.vpc.vpc_id

  public_subnets = module.vpc.public_subnets
}

output "efs_id" {
  description = "EFS ID. Use for efs-provisioner in Kubernetes."
  value       = module.efs.efs_id
}


# Zabbix module creates policies and role for Zabbix.
module "zabbix" {
  source        = "./zabbix"
  node_role_arn = aws_iam_role.node.arn
}


# Vault module creates policies and role for Vault.
#module "vault" {
#  source        = "./vault"
#  node_role_arn = aws_iam_role.node.arn
#}

#output "vault_kms_id" {
#  description = "KMS ID. Use for Vault auto-unseal."
#  value       = module.vault.vault_kms_id
#}


# Kubernetes module to manage Kubernetes resources
#module "kubernetes" {
#  source = "./kubernetes"
#  cluster_id = aws_eks_cluster.cluster.id
#}
