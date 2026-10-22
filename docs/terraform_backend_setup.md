# Terraform Backend Setup Guide

## Current Status: ✅ Using Local Backend

Due to AWS Organization Service Control Policy (SCP) restrictions, S3 bucket creation is blocked in your account.

**Temporary Solution:** Terraform is configured to use **local backend** for state management.

---

## 🚨 SCP Restriction Details

**Error Received:**
```
An error occurred (AccessDenied) when calling the CreateBucket operation: 
User: arn:aws:iam::200340799102:user/Kiro is not authorized to perform: 
s3:CreateBucket on resource with an explicit deny in a service control policy: 
arn:aws:organizations::251929332078:policy/o-8uelj711wm/service_control_policy/p-sdwf812t
```

**What This Means:**
- Your AWS account is part of an AWS Organization
- Organization admin has applied a Service Control Policy (SCP) that blocks S3 bucket creation
- Even AdministratorAccess users cannot override SCP restrictions

---

## 🛠️ Solutions

### Option 1: Use Local Backend (Current - ✅ Working)

**Pros:**
- Works immediately
- No dependency on S3/DynamoDB
- Good for testing and development

**Cons:**
- State file stored locally (not shared across team)
- No state locking (risk of concurrent modifications)
- State file lost if machine fails
- Not suitable for production

**Current Configuration:**
```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

---

### Option 2: Request S3 Bucket from Organization Admin (Recommended for Production)

**Steps:**

1. **Contact your AWS Organization Administrator** and request:
   - S3 bucket for Terraform state
   - DynamoDB table for state locking
   - Permissions to access these resources

2. **Required Resources:**

   **S3 Bucket:**
   - Name: `devsecops-terraform-state-<unique-id>`
   - Region: `us-east-1`
   - Versioning: Enabled
   - Encryption: Enabled
   - Block Public Access: All enabled

   **DynamoDB Table:**
   - Name: `devsecops-terraform-lock-<unique-id>`
   - Region: `us-east-1`
   - Partition Key: `LockID` (String)
   - Billing Mode: On-demand

3. **IAM Permissions Needed:**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:ListBucket",
           "s3:GetObject",
           "s3:PutObject",
           "s3:DeleteObject"
         ],
         "Resource": [
           "arn:aws:s3:::BUCKET_NAME",
           "arn:aws:s3:::BUCKET_NAME/*"
         ]
       },
       {
         "Effect": "Allow",
         "Action": [
           "dynamodb:DescribeTable",
           "dynamodb:GetItem",
           "dynamodb:PutItem",
           "dynamodb:DeleteItem"
         ],
         "Resource": "arn:aws:dynamodb:us-east-1:200340799102:table/TABLE_NAME"
       }
     ]
   }
   ```

4. **Once Resources Are Created, Update Backend:**

   Edit `terraform/s3_backend.tf`:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "actual-bucket-name-from-admin"
       key            = "task5/devsecops/terraform.tfstate"
       region         = "us-east-1"
       dynamodb_table = "actual-table-name-from-admin"
       encrypt        = true
     }
   }
   ```

5. **Migrate State:**
   ```powershell
   cd terraform
   terraform init -migrate-state
   ```

---

### Option 3: Use Different AWS Account (If Available)

If you have access to another AWS account without SCP restrictions:

1. Create S3 bucket and DynamoDB table there
2. Configure cross-account access
3. Update backend configuration with cross-account bucket

---

## 📋 Current Backend Configuration

**File:** `terraform/s3_backend.tf`

```hcl
# Backend temporarily using local state due to Organization SCP restrictions
# Contact AWS Organization admin to create S3 bucket and DynamoDB table
# Then migrate to S3 backend

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

---

## 🔄 How to Migrate from Local to S3 Backend Later

When S3 bucket and DynamoDB table are ready:

1. **Update `s3_backend.tf` with actual values:**
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "your-actual-bucket-name"
       key            = "task5/devsecops/terraform.tfstate"
       region         = "us-east-1"
       dynamodb_table = "your-actual-table-name"
       encrypt        = true
     }
   }
   ```

2. **Run migration:**
   ```powershell
   terraform init -migrate-state
   ```

3. **Terraform will prompt:**
   ```
   Do you want to copy existing state to the new backend?
   ```
   Type `yes`

4. **Verify:**
   ```powershell
   terraform state list
   ```

5. **Backup local state (optional):**
   ```powershell
   cp terraform.tfstate terraform.tfstate.backup
   ```

---

## 🎯 GitHub Actions Considerations

**Current Setup:** GitHub Actions can work with local backend, BUT state won't persist between runs.

**For Production:**
- GitHub Actions MUST use S3 backend
- Local backend state is lost after each workflow run
- This means infrastructure will be recreated every time (❌ BAD)

**Action Required:**
- For production deployments, S3 backend is MANDATORY
- Contact org admin ASAP to get S3 bucket created

---

## 🔍 Troubleshooting

### Issue: "Backend initialization required"
```powershell
terraform init -reconfigure
```

### Issue: "State file conflicts"
```powershell
terraform init -migrate-state
```

### Issue: "Cannot access S3 bucket"
Check:
1. Bucket exists: `aws s3 ls s3://BUCKET_NAME`
2. Permissions: Check IAM policies
3. Region correct: Must match backend config

### Issue: "DynamoDB table not found"
Check:
1. Table exists: `aws dynamodb describe-table --table-name TABLE_NAME`
2. Correct partition key: `LockID` (String)
3. Region matches backend config

---

## 📞 Who to Contact

**AWS Organization Administrator:**
- Request S3 bucket: `devsecops-terraform-state-<unique-suffix>`
- Request DynamoDB table: `devsecops-terraform-lock-<unique-suffix>`
- Request permissions to access both resources
- Provide this document for reference

**Organization Policy ARN:**
```
arn:aws:organizations::251929332078:policy/o-8uelj711wm/service_control_policy/p-sdwf812t
```

---

## ✅ Summary

| Aspect | Current Status | Recommended Action |
|--------|---------------|-------------------|
| Backend Type | Local | Contact org admin for S3 bucket |
| State Storage | Local file | S3 with versioning |
| State Locking | None | DynamoDB table |
| Production Ready | ❌ No | ✅ Yes (after S3 setup) |
| GitHub Actions | ⚠️ Works but state lost | ✅ Persistent state |

**Next Steps:**
1. ✅ Continue development with local backend (works now)
2. ⏳ Contact AWS org admin for S3 bucket creation
3. 🔄 Migrate to S3 backend when ready
4. 🚀 Deploy to production with S3 backend

---

**Last Updated:** October 22, 2026  
**Status:** Local backend active, S3 migration pending org admin approval
