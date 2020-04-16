# Policy for creating and deleting austintest users with access keys.
# aws_iam_policy.iam_austintest
resource "aws_iam_policy" "vault_iam" {
  name = "terraform_vault_iam"
  path = "/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "iam:AttachUserPolicy",
            "iam:CreateAccessKey",
            "iam:CreateUser",
            "iam:DeleteAccessKey",
            "iam:DeleteUser",
            "iam:DeleteUserPolicy",
            "iam:DetachUserPolicy",
            "iam:ListAccessKeys",
            "iam:ListAttachedUserPolicies",
            "iam:ListGroupsForUser",
            "iam:ListUserPolicies",
            "iam:PutUserPolicy",
          ]
          Effect   = "Allow"
          Resource = "arn:aws:iam::346367625676:user/*austintest*"
        },
      ]
      Version = "2012-10-17"
    }
  )
}

# Policy for accessing austin-vault S3 bucket.
# aws_iam_policy.s3_austin-vault
resource "aws_iam_policy" "vault_s3" {
  name = "terraform_vault_s3"
  path = "/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action   = "s3:*"
          Effect   = "Allow"
          Resource = "arn:aws:s3:::austin-vault/*"
        },
      ]
      Version = "2012-10-17"
    }
  )
}

# Policy for using KMS key to unseal.
# aws_iam_policy.vault_kms
resource "aws_iam_policy" "vault_kms" {
  name = "terraform_vault_kms"
  path = "/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:DescribeKey",
          ]
          Effect   = "Allow"
          Resource = aws_kms_key.vault.arn
        },
      ]
      Version = "2012-10-17"
    }
  )
}

# Vault role.
# aws_iam_role.vault
resource "aws_iam_role" "vault" {
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
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            AWS = var.node_role_arn
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  description           = "Role for Vault."
  force_detach_policies = false
  max_session_duration  = 3600
  name                  = "terraform_vault"
  path                  = "/"
  tags                  = {}
}

# Associates IAM policies with Vault role.
# aws_iam_role_policy_attachment.vault_iam
resource "aws_iam_role_policy_attachment" "vault_iam" {
  role       = aws_iam_role.vault.name
  policy_arn = aws_iam_policy.vault_iam.arn
}

# aws_iam_role_policy_attachment.vault_s3
resource "aws_iam_role_policy_attachment" "vault_s3" {
  role       = aws_iam_role.vault.name
  policy_arn = aws_iam_policy.vault_s3.arn
}

# aws_iam_role_policy_attachment.vault_kms
resource "aws_iam_role_policy_attachment" "vault_kms" {
  role       = aws_iam_role.vault.name
  policy_arn = aws_iam_policy.vault_kms.arn
}


# Bucket for Vault S3 backend
# aws_s3_bucket.austin-vault
resource "aws_s3_bucket" "austin-vault" {
  bucket = "terraform-austin-vault"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled    = false
    mfa_delete = false
  }
}

# Bucket policy for Vault bucket
# aws_s3_bucket_policy.austin-vault
resource "aws_s3_bucket_policy" "austin-vault" {
  bucket = "terraform-austin-vault"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = "s3:*"
          Effect = "Allow"
          Principal = {
            AWS = aws_iam_role.vault.arn
          }
          Resource = [
            "arn:aws:s3:::terraform-austin-vault",
            "arn:aws:s3:::terraform-austin-vault/*",
          ]
        },
      ]
      Version = "2012-10-17"
    }
  )
  depends_on = [aws_s3_bucket.austin-vault]
}

# Blocks all public access to Vault bucket.
# aws_s3_bucket_public_access_block.austin-vault:
resource "aws_s3_bucket_public_access_block" "austin-vault" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.austin-vault.id
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.austin-vault]
}

# KMS key for Vault auto-unseal
# aws_kms_key.vault
resource "aws_kms_key" "vault" {
  description = "KMS key for Vault auto-unseal"
}
