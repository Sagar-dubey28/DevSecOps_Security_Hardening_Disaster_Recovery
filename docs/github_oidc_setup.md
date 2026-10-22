# GitHub Actions OIDC Setup Guide

## Problem Diagnosis

### Root Cause
Your GitHub Actions workflow was failing with:
```
Error: Could not assume role with OIDC: Not authorized to perform sts:AssumeRoleWithWebIdentity
```

**The exact problem**: Your IAM role `GitHubActionsDeployRole` had a correct **trust policy** (allowing GitHub to assume the role) but was **missing IAM permissions** (what the role can do after being assumed).

Think of it like this:
- ✅ **Trust Policy** = Front door key (GitHub Actions can enter)
- ❌ **IAM Permissions** = Room access inside (no permissions to do anything)

## Current Configuration

### OIDC Provider
- **ARN**: `arn:aws:iam::200340799102:oidc-provider/token.actions.githubusercontent.com`
- **Status**: ✅ Already created (manually)
- **Client ID**: `sts.amazonaws.com`

### IAM Role
- **Name**: `GitHubActionsDeployRole`
- **ARN**: `arn:aws:iam::200340799102:role/GitHubActionsDeployRole`
- **Status**: ✅ Already created (manually)

### Trust Policy (Already Correct)
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::200340799102:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:Sagar-dubey28/DevSecOps_Security_Hardening_Disaster_Recovery:*"
                }
            }
        }
    ]
}
```

## Solution

### Quick Fix (Immediate)

Run the PowerShell script to attach permissions to your existing role:

```powershell
# Navigate to the scripts directory
cd d:\Cloud_Nexus\AWS_DevSecOps_Security_Hardening_Disaster_Recovery\scripts

# Run the fix script
.\fix_github_oidc_permissions.ps1
```

This script will attach two IAM policies to your `GitHubActionsDeployRole`:

1. **TerraformStateAccess** - Access to S3 state bucket and DynamoDB lock table
2. **InfrastructureManagement** - Permissions to manage AWS resources (EC2, VPC, IAM, etc.)

### Alternative: Manual AWS Console Setup

If you prefer to add permissions manually via AWS Console:

1. Go to **IAM Console** → **Roles** → **GitHubActionsDeployRole**
2. Click **Add permissions** → **Create inline policy**
3. Use the JSON editor to paste the policy from `scripts/fix_github_oidc_permissions.ps1`
4. Repeat for both policies (TerraformStateAccess and InfrastructureManagement)

## Verification Steps

After applying the fix:

### 1. Verify Role Policies
```powershell
aws iam list-role-policies --role-name GitHubActionsDeployRole
```

Expected output:
```json
{
    "PolicyNames": [
        "TerraformStateAccess",
        "InfrastructureManagement"
    ]
}
```

### 2. Verify GitHub Actions Configuration

Check your GitHub repository secrets:

- **Secret Name**: `AWS_ROLE_ARN`
- **Secret Value**: `arn:aws:iam::200340799102:role/GitHubActionsDeployRole`

Check your GitHub repository variables:

- **Variable Name**: `AWS_DEFAULT_REGION`
- **Variable Value**: Your AWS region (e.g., `us-east-1`)

### 3. Test the Workflow

Push a commit or manually trigger the workflow:

```bash
git add .
git commit -m "test: verify OIDC authentication"
git push origin main
```

Monitor the workflow in GitHub Actions. The "Configure AWS credentials using OIDC" step should now succeed.

## What the Fix Does

### Permissions Added

#### 1. Terraform State Access
- **S3 Bucket**: Read/Write access to Terraform state files
- **DynamoDB Table**: Lock table access for state locking
- **Purpose**: Allows Terraform to store and retrieve state

#### 2. Infrastructure Management

**EC2 & VPC**:
- Create/delete/modify EC2 instances
- Manage security groups
- Create/delete VPCs, subnets, route tables
- Manage NAT gateways and Internet gateways

**IAM**:
- Read IAM roles and policies
- Create/delete instance profiles
- Pass roles to EC2 instances

**CloudWatch & Logging**:
- Create/delete log groups
- Manage CloudWatch alarms
- Create EventBridge rules

**Security Services**:
- Manage CloudTrail
- Manage GuardDuty detectors
- Create SNS topics for alerts

**Storage**:
- Create/manage S3 buckets
- Configure bucket policies and encryption

## Troubleshooting

### Still Getting "Not Authorized" Error?

1. **Check OIDC Provider exists**:
   ```powershell
   aws iam list-open-id-connect-providers
   ```
   Should show: `token.actions.githubusercontent.com`

2. **Verify Role ARN in GitHub Secrets**:
   - Go to GitHub repo → Settings → Secrets and variables → Actions
   - Verify `AWS_ROLE_ARN` = `arn:aws:iam::200340799102:role/GitHubActionsDeployRole`

3. **Check Repository Name**:
   - Trust policy expects: `repo:Sagar-dubey28/DevSecOps_Security_Hardening_Disaster_Recovery:*`
   - Verify your repo matches this exactly (case-sensitive)

4. **Check Token Audience**:
   - In `.github/workflows/main.yaml`, the `aws-actions/configure-aws-credentials@v4` action automatically uses `sts.amazonaws.com` as audience
   - No changes needed, but verify your trust policy has this in the condition

### Permission Denied for Specific Resources?

If you get permission errors for specific AWS services:

1. Check which action failed in the GitHub Actions log
2. Add the missing permission to the `InfrastructureManagement` policy
3. Update the policy:
   ```powershell
   aws iam put-role-policy --role-name GitHubActionsDeployRole --policy-name InfrastructureManagement --policy-document file://path/to/updated-policy.json
   ```

## Security Best Practices

### Principle of Least Privilege

The current permissions are scoped to allow Terraform operations. Consider:

1. **Resource Restrictions**: Limit actions to specific ARN patterns
   ```json
   "Resource": "arn:aws:ec2:*:200340799102:instance/i-*"
   ```

2. **Condition Keys**: Add conditions to further restrict access
   ```json
   "Condition": {
       "StringEquals": {
           "aws:RequestedRegion": "us-east-1"
       }
   }
   ```

3. **Regular Audits**: Review CloudTrail logs for role usage
   ```powershell
   aws cloudtrail lookup-events --lookup-attributes AttributeKey=Username,AttributeValue=GitHubActionsDeployRole
   ```

### Monitoring

Set up CloudWatch alarms for unusual activity:

1. **High API Call Volume**: Alert on excessive API calls
2. **Failed Authentication**: Alert on repeated AssumeRole failures
3. **Sensitive Actions**: Alert on IAM policy changes or resource deletions

## Terraform Configuration (For Future Use)

The repository now includes `terraform/github_oidc_setup.tf` which can manage your OIDC configuration via Terraform in the future. 

**Note**: Since you've created the role manually, Terraform will try to import it. To avoid conflicts:

1. Either keep managing the role manually (current approach)
2. Or import the existing role into Terraform:
   ```bash
   cd terraform
   terraform import aws_iam_role.github_actions GitHubActionsDeployRole
   ```

## References

- [GitHub Actions: Configuring OpenID Connect in AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS IAM: Creating OpenID Connect providers](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [aws-actions/configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials)

## Summary

✅ **Problem**: Missing IAM permissions on your GitHub Actions role
✅ **Solution**: Attached comprehensive permissions via PowerShell script
✅ **Result**: GitHub Actions can now authenticate and manage AWS infrastructure

Your OIDC setup is now complete and ready to use!
