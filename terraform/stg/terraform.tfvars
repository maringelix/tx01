# Staging Environment Configuration
environment        = "stg"
aws_region         = "us-east-1"
project_name       = "tx01"
vpc_cidr           = "10.0.0.0/16"
instance_type      = "t2.micro"
instance_count     = 2
docker_image_tag   = "latest"
enable_waf         = true

# EKS Configuration (set to false by default, enable via workflow)
enable_eks              = false
eks_node_instance_type  = "t3.small"
eks_node_desired_size   = 2
eks_node_min_size       = 1
eks_node_max_size       = 4

# IAM User for Kubernetes Access
iam_user_arn            = "arn:aws:iam::894222083614:user/devops-tx01"
iam_user_name           = "devops-tx01"

tags = {
  Environment = "staging"
  CostCenter  = "DevOps"
  Owner       = "DevOps Team"
  Terraform   = "true"
}
