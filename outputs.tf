output "region" {
  description = "Region deployed to."
  value       = var.region
}

output "cluster_name" {
  description = "Name of EKS cluster."
  value       = module.eks.cluster_name
}

