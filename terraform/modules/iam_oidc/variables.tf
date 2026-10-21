variable "project_name" { type = string }
variable "gitlab_url" { type = string }
variable "gitlab_project_path" { type = string }
variable "gitlab_ref" { type = string }
variable "aws_region" { type = string }
variable "state_bucket_arn" { type = string }
variable "state_lock_table_arn" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
