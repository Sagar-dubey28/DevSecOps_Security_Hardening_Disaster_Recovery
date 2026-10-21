# Edit these values to match a pre-created bucket/table before `terraform init`.
# Backend blocks do not support normal Terraform input variables.
terraform {
  backend "s3" {
    bucket         = "REPLACE_WITH_UNIQUE_TF_STATE_BUCKET"
    key            = "task5/devsecops/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "REPLACE_WITH_TF_LOCK_TABLE"
    encrypt        = true
  }
}
