# PowerShell script to fix GitHub Actions OIDC role permissions
# This attaches the necessary IAM policies to your existing GitHubActionsDeployRole

$ErrorActionPreference = "Stop"

$ROLE_NAME = "GitHubActionsDeployRole"
$ACCOUNT_ID = "200340799102"
$PROJECT_NAME = "cloud-nexus-devsecops"
$AWS_REGION = "us-east-1"  # Change this to your region

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "GitHub OIDC Role Permissions Fix" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Role: $ROLE_NAME"
Write-Host "Account: $ACCOUNT_ID"
Write-Host ""

# Check if role exists
Write-Host "Checking if role exists..." -ForegroundColor Yellow
try {
    aws iam get-role --role-name $ROLE_NAME | Out-Null
    Write-Host "✓ Role found: $ROLE_NAME" -ForegroundColor Green
} catch {
    Write-Host "✗ Role not found: $ROLE_NAME" -ForegroundColor Red
    exit 1
}

# Create Terraform State Access Policy
Write-Host ""
Write-Host "Creating Terraform State Access Policy..." -ForegroundColor Yellow

$statePolicyJson = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "StateBucketList",
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::*-terraform-state"
    },
    {
      "Sid": "StateObjectAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::*-terraform-state/*"
    },
    {
      "Sid": "LockTableAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:$ACCOUNT_ID:table/*-terraform-lock"
    }
  ]
}
"@

$statePolicyJson | Out-File -FilePath "$env:TEMP\state-policy.json" -Encoding utf8

aws iam put-role-policy `
    --role-name $ROLE_NAME `
    --policy-name "TerraformStateAccess" `
    --policy-document "file://$env:TEMP\state-policy.json"

Write-Host "✓ Terraform State Access Policy attached" -ForegroundColor Green

# Create Infrastructure Management Policy
Write-Host ""
Write-Host "Creating Infrastructure Management Policy..." -ForegroundColor Yellow

$infraPolicyJson = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EC2Management",
      "Effect": "Allow",
      "Action": [
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
      ],
      "Resource": "*"
    },
    {
      "Sid": "VPCManagement",
      "Effect": "Allow",
      "Action": [
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
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMReadAccess",
      "Effect": "Allow",
      "Action": [
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
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMInstanceProfileManagement",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:PassRole"
      ],
      "Resource": [
        "arn:aws:iam::$ACCOUNT_ID:instance-profile/$PROJECT_NAME-*",
        "arn:aws:iam::$ACCOUNT_ID:role/$PROJECT_NAME-*"
      ]
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",
        "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy",
        "logs:TagLogGroup",
        "logs:UntagLogGroup"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3BucketManagement",
      "Effect": "Allow",
      "Action": [
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
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::$PROJECT_NAME-*",
        "arn:aws:s3:::$PROJECT_NAME-*/*"
      ]
    },
    {
      "Sid": "CloudTrailManagement",
      "Effect": "Allow",
      "Action": [
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
      ],
      "Resource": "*"
    },
    {
      "Sid": "GuardDutyManagement",
      "Effect": "Allow",
      "Action": [
        "guardduty:CreateDetector",
        "guardduty:DeleteDetector",
        "guardduty:UpdateDetector",
        "guardduty:ListDetectors",
        "guardduty:GetDetector",
        "guardduty:TagResource",
        "guardduty:UntagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SNSManagement",
      "Effect": "Allow",
      "Action": [
        "sns:CreateTopic",
        "sns:DeleteTopic",
        "sns:SetTopicAttributes",
        "sns:GetTopicAttributes",
        "sns:Subscribe",
        "sns:Unsubscribe",
        "sns:ListSubscriptionsByTopic",
        "sns:SetSubscriptionAttributes",
        "sns:TagResource",
        "sns:UntagResource"
      ],
      "Resource": "arn:aws:sns:*:$ACCOUNT_ID:$PROJECT_NAME-*"
    },
    {
      "Sid": "SNSPolicyManagement",
      "Effect": "Allow",
      "Action": [
        "sns:GetTopicAttributes",
        "sns:SetTopicAttributes"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchAlarmsAndEvents",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DeleteAlarms",
        "cloudwatch:DescribeAlarms",
        "events:PutRule",
        "events:DeleteRule",
        "events:PutTargets",
        "events:RemoveTargets",
        "events:DescribeRule",
        "events:ListTargetsByRule"
      ],
      "Resource": "*"
    },
    {
      "Sid": "STSGetCallerIdentity",
      "Effect": "Allow",
      "Action": "sts:GetCallerIdentity",
      "Resource": "*"
    }
  ]
}
"@

$infraPolicyJson | Out-File -FilePath "$env:TEMP\infra-policy.json" -Encoding utf8

aws iam put-role-policy `
    --role-name $ROLE_NAME `
    --policy-name "InfrastructureManagement" `
    --policy-document "file://$env:TEMP\infra-policy.json"

Write-Host "✓ Infrastructure Management Policy attached" -ForegroundColor Green

# Verify role policies
Write-Host ""
Write-Host "Verifying attached policies..." -ForegroundColor Yellow
aws iam list-role-policies --role-name $ROLE_NAME

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✓ SUCCESS: All permissions attached!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your GitHubActionsDeployRole now has:"
Write-Host "  1. Terraform State Access" -ForegroundColor Yellow
Write-Host "  2. Infrastructure Management (EC2, VPC, IAM, CloudWatch, etc.)" -ForegroundColor Yellow
Write-Host ""
Write-Host "You can now re-run your GitHub Actions workflow." -ForegroundColor Green
Write-Host ""

# Cleanup
Remove-Item "$env:TEMP\state-policy.json" -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\infra-policy.json" -ErrorAction SilentlyContinue
