output "gitlab_ci_role_arn" { value = aws_iam_role.gitlab_ci.arn }
output "gitlab_oidc_provider_arn" { value = aws_iam_openid_connect_provider.gitlab.arn }
