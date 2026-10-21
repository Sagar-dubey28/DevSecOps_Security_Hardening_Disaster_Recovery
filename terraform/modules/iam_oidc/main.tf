locals {
  gitlab_host    = trimsuffix(trimprefix(var.gitlab_url, "https://"), "/")
  gitlab_issuer  = var.gitlab_url
  gitlab_subject = "project_path:${var.gitlab_project_path}:ref_type:branch:ref:${var.gitlab_ref}"
}
resource "aws_iam_openid_connect_provider" "gitlab" {
  url            = local.gitlab_issuer
  client_id_list = ["sts.amazonaws.com"]
  # AWS now supports thumbprint discovery for many providers; omit thumbprint_list
  # unless your AWS provider/account requires an explicitly configured CA thumbprint.
  tags = var.tags
}
resource "aws_iam_role" "gitlab_ci" {
  name = "${var.project_name}-gitlab-ci"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.gitlab.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.gitlab_host}:aud" = "sts.amazonaws.com"
          "${local.gitlab_host}:sub" = local.gitlab_subject
        }
      }
    }]
  })
  max_session_duration = 3600
  tags                 = var.tags
}
# Scope this role to the resources the pipeline actually manages. State bucket/table
# permissions are included; the example infrastructure policy is intentionally not AdministratorAccess.
resource "aws_iam_role_policy" "gitlab_ci_state" {
  name = "${var.project_name}-state-access"
  role = aws_iam_role.gitlab_ci.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Sid = "StateBucketList", Effect = "Allow", Action = ["s3:ListBucket"], Resource = var.state_bucket_arn },
    { Sid = "StateObjectAccess", Effect = "Allow", Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"], Resource = "${var.state_bucket_arn}/*" },
    { Sid = "LockTableAccess", Effect = "Allow", Action = ["dynamodb:DescribeTable", "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:UpdateItem"], Resource = var.state_lock_table_arn },
    { Sid = "TerraformReadDiscovery", Effect = "Allow", Action = ["sts:GetCallerIdentity", "ec2:Describe*", "iam:GetRole", "iam:GetPolicy", "iam:GetPolicyVersion", "iam:ListAttachedRolePolicies", "iam:ListRolePolicies", "iam:ListOpenIDConnectProviders", "iam:GetOpenIDConnectProvider", "logs:DescribeLogGroups", "cloudtrail:DescribeTrails", "guardduty:ListDetectors", "s3:GetBucketLocation", "s3:GetBucketVersioning", "s3:GetEncryptionConfiguration", "s3:GetBucketPublicAccessBlock", "sns:GetTopicAttributes", "sns:ListSubscriptionsByTopic"], Resource = "*" }
  ] })
}
