# Production outputs
output "alb_dns_name" {
  description = "ALB DNS Name (PRD)"
  value       = module.infrastructure.alb_dns_name
}

output "ecr_repository_url" {
  description = "ECR Repository URL (PRD)"
  value       = module.infrastructure.ecr_repository_url
}

output "instance_public_ips" {
  description = "EC2 Instance Public IPs (PRD)"
  value       = module.infrastructure.instance_public_ips
}

output "vpc_id" {
  description = "VPC ID (PRD)"
  value       = module.infrastructure.vpc_id
}
