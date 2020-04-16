# Policy for Route53 record changes
# aws_iam_policy.update_route53:
resource "aws_iam_policy" "update_route53" {
  description = "Policy to allow pods to update Route53 records"
  name        = "terraform_update_route53_2"
  path        = "/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "route53:ChangeResourceRecordSets",
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:route53:::hostedzone/*",
          ]
        },
        {
          Action = [
            "route53:ListHostedZones",
            "route53:ListResourceRecordSets",
          ]
          Effect = "Allow"
          Resource = [
            "*",
          ]
        },
      ]
      Version = "2012-10-17"
    }
  )
}

# Policy for describing EC2 instances. 
# Note: Not strictly necessary for this use-case because worker nodes already have this.
# aws_iam_policy.describe_ec2:
resource "aws_iam_policy" "describe_ec2" {
  description = "Policy to allow describing EC2 instances"
  name        = "terraform_describe_ec2_2"
  path        = "/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "ec2:DescribeInstances",
          ]
          Effect = "Allow"
          Resource = [
            "*",
          ]
        },
      ]
      Version = "2012-10-17"
    }
  )
}

# Policy for access to Zabbix credentials in Secrets Manager.
# aws_iam_policy.zabbix_credentials:
resource "aws_iam_policy" "zabbix_credentials" {
  description = "Policy to allow access to Zabbix credentials in Secrets Manager"
  name        = "terraform_zabbix_credentials_2"
  path        = "/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "secretsmanager:GetSecretValue",
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:secretsmanager:ap-northeast-1:346367625676:secret:zabbix_credentials-9XChz6",
          ]
        },
      ]
      Version = "2012-10-17"
    }
  )
}

# Zabbix role.
# aws_iam_role.zabbix
resource "aws_iam_role" "zabbix" {
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
          Sid = ""
        },
      ]
      Version = "2012-10-17"
    }
  )
  description           = "Role for Zabbix."
  force_detach_policies = false
  max_session_duration  = 3600
  name                  = "terraform_zabbix2"
  path                  = "/"
  tags                  = {}
}

# Associates IAM policies with Zabbix role.
# aws_iam_role_policy_attachment.zabbix_update_route53
resource "aws_iam_role_policy_attachment" "zabbix_update_route53" {
  role       = aws_iam_role.zabbix.name
  policy_arn = aws_iam_policy.update_route53.arn
}

# aws_iam_role_policy_attachment.zabbix_describe_ec2
resource "aws_iam_role_policy_attachment" "zabbix_describe_ec2" {
  role       = aws_iam_role.zabbix.name
  policy_arn = aws_iam_policy.describe_ec2.arn
}

# aws_iam_role_policy_attachment.zabbix_zabbix_credentials
resource "aws_iam_role_policy_attachment" "zabbix_zabbix_credentials" {
  role       = aws_iam_role.zabbix.name
  policy_arn = aws_iam_policy.zabbix_credentials.arn
}
