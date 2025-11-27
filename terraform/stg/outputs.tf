# Staging outputs
output "alb_dns_name" {
  description = "ALB DNS Name (STG)"
  value       = module.infrastructure.alb_dns_name
}

output "ecr_repository_url" {
  description = "ECR Repository URL (STG)"
  value       = module.infrastructure.ecr_repository_url
}

output "instance_public_ips" {
  description = "EC2 Instance Public IPs (STG)"
  value       = module.infrastructure.instance_public_ips
}

output "vpc_id" {
  description = "VPC ID (STG)"
  value       = module.infrastructure.vpc_id
}
