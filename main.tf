# Declare region and role for Terraform to assume
provider "aws" {
  region = var.region
  assume_role {
    role_arn = var.role_arn
  }
}

# Remote backend for Terraform to use
terraform {
  backend "s3" {
    bucket  = "austin-terraform-test"
    encrypt = true
    key     = "terraform.tfstate"
    region  = "ap-southeast-1"
  }
}


# Deploy VPC, EKS cluster, necessary roles and security groups, optional modules for EFS and Zabbix
module "eks" {
  source = "./eks"
}


