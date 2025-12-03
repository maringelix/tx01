# Staging Environment Configuration
environment        = "stg"
aws_region         = "us-east-1"
project_name       = "tx01"
vpc_cidr           = "10.0.0.0/16"
instance_type      = "t3.micro"  # Free Tier eligible (t2.micro is deprecated)
instance_count     = 2
docker_image_tag   = "latest"
enable_waf         = true

tags = {
  Environment = "staging"
  CostCenter  = "DevOps"
  Owner       = "DevOps Team"
  Terraform   = "true"
}
