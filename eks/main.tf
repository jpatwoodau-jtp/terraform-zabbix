# Fetches availability zones in the region
# data.aws_availability_zones.available
data "aws_availability_zones" "available" {
}

# VPC to be used by EKS cluster.
# module.vpc:
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.6.0"

  name            = "terraform_vpc"
  cidr            = "10.0.0.0/16"
  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = false
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# Cluster security group.
# aws_security_group.cluster_sg:
resource "aws_security_group" "cluster_sg" {
  description = "allow all traffic within cluster"
  egress = [
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = "Allow all outbound traffic"
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    },
  ]
  ingress = [
    {
      cidr_blocks      = []
      description      = "Allow all traffic within cluster"
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = true
      to_port          = 0
    },
  ]
  name                   = "austin-eks-sg"
  tags                   = {}
  vpc_id                 = module.vpc.vpc_id
  revoke_rules_on_delete = false

  timeouts {}
}

# List of AWS-managed IAM policies for cluster role.
# var.cluster_iam_policies
variable "cluster_iam_policies" {
  description = "List of IAM policies to be attached to cluster role."
  default = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  ]
}

# Cluster role.
# aws_iam_role.cluster
resource "aws_iam_role" "cluster" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "eks.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  description           = "Allows EKS to manage clusters on your behalf."
  force_detach_policies = false
  max_session_duration  = 3600
  name                  = "terraform_cluster2"
  path                  = "/"
  tags                  = {}
}

# Associates IAM policies with cluster role.
# aws_iam_role_policy_attachment.cluster
resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  count      = length(var.cluster_iam_policies)
  policy_arn = var.cluster_iam_policies[count.index]
}

# List of AWS-managed IAM policies for node role.
# var.node_iam_policies
variable "node_iam_policies" {
  description = "List of IAM policies to be attached to worker node role."
  default = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]
}

# Node role.
# aws_iam_role.node
resource "aws_iam_role" "node" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  description           = "Allows EKS worker nodes to call AWS services on your behalf"
  force_detach_policies = false
  max_session_duration  = 3600
  name                  = "terraform_node2"
  path                  = "/"
  tags                  = {}
}

# Associates IAM policies with node role.
# aws_iam_role_policy_attachment.node
resource "aws_iam_role_policy_attachment" "node" {
  role       = aws_iam_role.node.name
  count      = length(var.node_iam_policies)
  policy_arn = var.node_iam_policies[count.index]
}

# EKS cluster.
# aws_eks_cluster.cluster:
resource "aws_eks_cluster" "cluster" {
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  tags     = {}
  version  = "1.15"
  timeouts {}
  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true
    public_access_cidrs = [
      "0.0.0.0/0",
    ]
    security_group_ids = [
      aws_security_group.cluster_sg.id,
    ]
    subnet_ids = module.vpc.public_subnets
  }
  depends_on = [aws_iam_role_policy_attachment.cluster]
}

# AWS-managed worker node group for the cluster.
# aws_eks_node_group.nodegroup
resource "aws_eks_node_group" "nodegroup" {
  ami_type     = "AL2_x86_64"
  cluster_name = aws_eks_cluster.cluster.name
  disk_size    = 20
  instance_types = [
    "t3.medium",
  ]
  labels          = {}
  node_group_name = "austin-nodes"
  node_role_arn   = aws_iam_role.node.arn
  release_version = "1.15.10-20200228"
  subnet_ids      = module.vpc.public_subnets
  tags = {
    "Name" = "austin-nodes"
  }
  version = "1.15"
  remote_access {
    ec2_ssh_key               = "austin_singapore_key"
    source_security_group_ids = []
  }
  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 1
  }
  timeouts {}
}
