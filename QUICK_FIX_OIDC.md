# 🔧 QUICK FIX: GitHub Actions OIDC Error

## ❌ The Problem

```
Error: Could not assume role with OIDC: Not authorized to perform sts:AssumeRoleWithWebIdentity
```

## ✅ Root Cause (EXACT)

Your `GitHubActionsDeployRole` has:
- ✅ **Trust Policy** = Correct (allows GitHub to assume the role)
- ❌ **IAM Permissions** = **MISSING** (role can't do anything after being assumed)

**Analogy**: You have the key to enter the building (trust policy), but no keys to any rooms inside (permissions).

## 🚀 The Fix (2 Minutes)

### Step 1: Run This Command

Open PowerShell in this directory and run:

```powershell
.\scripts\fix_github_oidc_permissions.ps1
```

### Step 2: Verify

Check that policies were attached:

```powershell
aws iam list-role-policies --role-name GitHubActionsDeployRole
```

Should show:
```
- TerraformStateAccess
- InfrastructureManagement
```

### Step 3: Re-run GitHub Actions

Push any commit or re-run the failed workflow. It should now work! ✅

## 📋 What the Script Does

Attaches two inline policies to your `GitHubActionsDeployRole`:

1. **TerraformStateAccess**: S3 + DynamoDB for Terraform state
2. **InfrastructureManagement**: EC2, VPC, IAM, CloudWatch, CloudTrail, GuardDuty, SNS permissions

## 🔍 Verification Checklist

Before running the workflow again, verify:

- [ ] OIDC Provider exists: `token.actions.githubusercontent.com`
- [ ] Role ARN in GitHub Secrets: `arn:aws:iam::200340799102:role/GitHubActionsDeployRole`
- [ ] Repository name matches: `Sagar-dubey28/DevSecOps_Security_Hardening_Disaster_Recovery`
- [ ] AWS region variable set in GitHub
- [ ] Permissions attached (after running script)

## 🆘 Still Not Working?

1. **Check OIDC Provider**:
   ```powershell
   aws iam get-open-id-connect-provider --open-id-connect-provider-arn arn:aws:iam::200340799102:oidc-provider/token.actions.githubusercontent.com
   ```

2. **Check Role Trust Policy**:
   ```powershell
   aws iam get-role --role-name GitHubActionsDeployRole --query 'Role.AssumeRolePolicyDocument'
   ```

3. **Check GitHub Secrets**:
   - Go to: `https://github.com/Sagar-dubey28/DevSecOps_Security_Hardening_Disaster_Recovery/settings/secrets/actions`
   - Verify `AWS_ROLE_ARN` is set correctly

## 📚 Full Documentation

See `docs/github_oidc_setup.md` for complete details.

---

**TL;DR**: Your role had no permissions. Run `.\scripts\fix_github_oidc_permissions.ps1` to fix it. Done! 🎉
