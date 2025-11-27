terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3 backend for remote state management with DynamoDB locking
  backend "s3" {
    bucket         = "tx01-terraform-state-maringelix-2025"
    key            = "tx01/prd/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "tx01-terraform-state-maringelix-2025-locks"
  }
}

module "infrastructure" {
  source = "../modules"
  
  project_name          = "tx01"
  environment           = "prd"
  vpc_cidr              = "10.1.0.0/16"
  availability_zones    = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs   = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs  = ["10.1.11.0/24", "10.1.12.0/24"]
  instance_type         = "t3.small"
  ami_id                = "ami-0c02fb55b34e3cf00" # Amazon Linux 2023
  waf_ip_whitelist      = []
  instance_count        = 3
}
