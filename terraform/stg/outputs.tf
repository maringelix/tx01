# Staging outputs
output "alb_dns_name" {
  description = "ALB DNS Name (STG)"
  value       = module.networking.alb_dns_name
}

output "ecr_repository_url" {
  description = "ECR Repository URL (STG)"
  value       = module.networking.ecr_repository_url
}

output "instance_public_ips" {
  description = "EC2 Instance Public IPs (STG)"
  value       = module.networking.instance_public_ips
}

output "vpc_id" {
  description = "VPC ID (STG)"
  value       = module.networking.vpc_id
}
