# Production Main Configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Descomente para usar S3 backend
  # backend "s3" {
  #   bucket         = "seu-bucket-terraform-state-prd"
  #   key            = "tx01/prd/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

# Import all module definitions
module "networking" {
  source = "../modules"
}

# Local variables for environment
locals {
  environment = "prd"
}
