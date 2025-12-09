# Staging Environment Configuration
environment        = "stg"
aws_region         = "us-east-1"
project_name       = "tx01"
vpc_cidr           = "10.0.0.0/16"
instance_type      = "t3.micro"  # Free Tier eligible (t2.micro is deprecated)
instance_count     = 0  # EC2s disabled (using EKS only)
docker_image_tag   = "latest"
enable_waf         = true

# EKS Configuration
enable_eks              = true  # Set to false to disable EKS
eks_node_instance_type  = "t3.small"  # 2 vCPU, 2GB RAM - supports full observability stack
eks_node_desired_size   = 4  # Optimal for app + observability + gatekeeper (~44 pod capacity)
eks_node_min_size       = 2
eks_node_max_size       = 6  # Allow scaling for peak loads

# IAM User for EKS Access
iam_user_arn  = "arn:aws:iam::894222083614:user/devops-tx01"
iam_user_name = "devops-tx01"

tags = {
  Environment = "staging"
  CostCenter  = "DevOps"
  Owner       = "DevOps Team"
  Terraform   = "true"
}
