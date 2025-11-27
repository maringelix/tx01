# Production Environment Configuration
environment        = "prd"
aws_region         = "us-east-1"
project_name       = "tx01"
vpc_cidr           = "10.1.0.0/16"
instance_type      = "t2.micro"
instance_count     = 2
docker_image_tag   = "latest"
enable_waf         = true

tags = {
  Environment = "production"
  CostCenter  = "DevOps"
  Owner       = "DevOps Team"
  Terraform   = "true"
}
