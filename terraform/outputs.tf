output "vpc_id" { value = module.vpc.vpc_id }
output "private_subnet_ids" { value = module.vpc.private_subnet_ids }
output "public_subnet_ids" { value = module.vpc.public_subnet_ids }
output "instance_id" { value = module.compute.instance_id }
output "instance_private_ip" { value = module.compute.private_ip }
output "gitlab_ci_role_arn" {
  value       = module.iam_oidc.gitlab_ci_role_arn
  description = "Configure this ARN as protected GitLab CI variable AWS_ROLE_ARN."
}
output "security_alert_topic_arn" { value = aws_sns_topic.security_alerts.arn }
output "cloudtrail_name" { value = aws_cloudtrail.main.name }
