# Backend temporarily commented out due to Organization SCP restrictions
# Contact AWS Organization admin to create S3 bucket and DynamoDB table
# Then uncomment and configure this block

# terraform {
#   backend "s3" {
#     bucket         = "REPLACE_WITH_UNIQUE_TF_STATE_BUCKET"
#     key            = "task5/devsecops/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "REPLACE_WITH_TF_LOCK_TABLE"
#     encrypt        = true
#   }
# }

# Using local backend for now
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
