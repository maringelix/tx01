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

module "networking" {
  source = "../modules"
}

locals {
  environment = "prd"
}
