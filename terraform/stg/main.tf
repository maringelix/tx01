/*
  Backend example (S3 + DynamoDB) - update the values below with your bucket/table names
  and then uncomment this block (remove the surrounding comment markers) OR run
  `terraform init -backend-config="bucket=..." -backend-config="key=..." -backend-config="region=..." -backend-config="dynamodb_table=..."`

  Notes:
  - `bucket` must be globally unique.
  - `key` is the path where the state file is stored.
  - `dynamodb_table` is the DynamoDB table used for state locking.
  - After configuring the backend, run `terraform init` in this directory to migrate state.

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Example backend (UNCOMMENT and replace values):
  # backend "s3" {
  #   bucket         = "tx01-terraform-state-maringelix-2025"
  #   key            = "tx01/stg/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "tx01-terraform-state-maringelix-2025-locks"
  # }
}

module "networking" {
  source = "../modules"
}

locals {
  environment = "stg"
}

*/
