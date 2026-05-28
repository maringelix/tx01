output "role_arn" {
  description = "ARN of the GitHub Actions IAM role. Publish as the AWS_DEPLOY_ROLE_ARN GitHub Actions variable."
  value       = aws_iam_role.github_actions.arn
}

output "role_name" {
  description = "Name of the GitHub Actions IAM role."
  value       = aws_iam_role.github_actions.name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider (created or reused)."
  value       = local.provider_arn
}
