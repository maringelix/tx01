# Staging Environment Configuration
environment        = "stg"
aws_region         = "us-east-1"
project_name       = "tx01"
vpc_cidr           = "10.0.0.0/16"
instance_type      = "t3.micro"  # Free Tier eligible (t2.micro is deprecated)
instance_count     = 2
docker_image_tag   = "latest"
enable_waf         = true

# EKS Configuration
enable_eks              = false  # Set to true when ready to provision EKS
eks_node_instance_type  = "t3.medium"  # Minimum recommended for EKS nodes
eks_node_desired_size   = 2
eks_node_min_size       = 1
eks_node_max_size       = 4

# IAM User for EKS Access
iam_user_arn  = "arn:aws:iam::894222083614:user/devops-tx01"
iam_user_name = "devops-tx01"

tags = {
  Environment = "staging"
  CostCenter  = "DevOps"
  Owner       = "DevOps Team"
  Terraform   = "true"
}
