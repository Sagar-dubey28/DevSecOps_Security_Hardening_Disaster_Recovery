# GitHub OIDC Configuration for GitHub Actions
# This file creates the necessary IAM resources for GitHub Actions to authenticate via OIDC

# Data source to get the existing OIDC provider (if it exists)
data "aws_iam_openid_connect_provider" "github" {
  # If the provider exists, this will fetch it; if not, create it below
  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

# If the OIDC provider doesn't exist, uncomment this resource to create it
# resource "aws_iam_openid_connect_provider" "github" {
#   url             = "https://token.actions.githubusercontent.com"
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
#   tags            = var.tags
# }

# IAM Role for GitHub Actions with proper trust policy
resource "aws_iam_role" "github_actions" {
  name        = "GitHubActionsDeployRole"
  description = "IAM role for GitHub Actions OIDC authentication"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:Sagar-dubey28/DevSecOps_Security_Hardening_Disaster_Recovery:*"
        }
      }
    }]
  })

  max_session_duration = 3600
  tags                 = var.tags
}

# IAM Policy for Terraform State Management
resource "aws_iam_role_policy" "github_actions_state" {
  name = "TerraformStateAccess"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "StateBucketList"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = var.state_bucket_arn
      },
      {
        Sid    = "StateObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.state_bucket_arn}/*"
      },
      {
        Sid    = "LockTableAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = var.state_lock_table_arn
      }
    ]
  })
}

# IAM Policy for Infrastructure Management (EC2, VPC, Security Groups, etc.)
resource "aws_iam_role_policy" "github_actions_infrastructure" {
  name = "InfrastructureManagement"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2Management"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:ModifyInstanceAttribute",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:CreateKeyPair",
          "ec2:DeleteKeyPair",
          "ec2:ImportKeyPair"
        ]
        Resource = "*"
      },
      {
        Sid    = "VPCManagement"
        Effect = "Allow"
        Action = [
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:ModifyVpcAttribute",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:ModifySubnetAttribute",
          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:CreateNatGateway",
          "ec2:DeleteNatGateway",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:AllocateAddress",
          "ec2:ReleaseAddress",
          "ec2:AssociateAddress",
          "ec2:DisassociateAddress",
          "ec2:CreateFlowLogs",
          "ec2:DeleteFlowLogs"
        ]
        Resource = "*"
      },
      {
        Sid    = "IAMReadAccess"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:GetInstanceProfile",
          "iam:ListOpenIDConnectProviders",
          "iam:GetOpenIDConnectProvider"
        ]
        Resource = "*"
      },
      {
        Sid    = "IAMInstanceProfileManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.project_name}-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"
        ]
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:DescribeLogGroups",
          "logs:PutRetentionPolicy",
          "logs:TagLogGroup",
          "logs:UntagLogGroup"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3BucketManagement"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:PutBucketVersioning",
          "s3:PutBucketEncryption",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketPolicy",
          "s3:GetBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:PutBucketLifecycleConfiguration",
          "s3:GetBucketLifecycleConfiguration",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:GetEncryptionConfiguration",
          "s3:GetBucketPublicAccessBlock",
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${var.project_name}-*"
      },
      {
        Sid    = "CloudTrailManagement"
        Effect = "Allow"
        Action = [
          "cloudtrail:CreateTrail",
          "cloudtrail:DeleteTrail",
          "cloudtrail:UpdateTrail",
          "cloudtrail:StartLogging",
          "cloudtrail:StopLogging",
          "cloudtrail:PutEventSelectors",
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:AddTags",
          "cloudtrail:RemoveTags"
        ]
        Resource = "*"
      },
      {
        Sid    = "GuardDutyManagement"
        Effect = "Allow"
        Action = [
          "guardduty:CreateDetector",
          "guardduty:DeleteDetector",
          "guardduty:UpdateDetector",
          "guardduty:ListDetectors",
          "guardduty:GetDetector",
          "guardduty:TagResource",
          "guardduty:UntagResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "SNSManagement"
        Effect = "Allow"
        Action = [
          "sns:CreateTopic",
          "sns:DeleteTopic",
          "sns:SetTopicAttributes",
          "sns:GetTopicAttributes",
          "sns:Subscribe",
          "sns:Unsubscribe",
          "sns:ListSubscriptionsByTopic",
          "sns:TagResource",
          "sns:UntagResource"
        ]
        Resource = "arn:aws:sns:*:${data.aws_caller_identity.current.account_id}:${var.project_name}-*"
      },
      {
        Sid    = "CloudWatchAlarmsAndEvents"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarms",
          "events:PutRule",
          "events:DeleteRule",
          "events:PutTargets",
          "events:RemoveTargets",
          "events:DescribeRule",
          "events:ListTargetsByRule"
        ]
        Resource = "*"
      },
      {
        Sid    = "STSGetCallerIdentity"
        Effect = "Allow"
        Action = "sts:GetCallerIdentity"
        Resource = "*"
      }
    ]
  })
}
