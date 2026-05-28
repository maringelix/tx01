terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote backend: pass via 'terraform init -backend-config=backend.hcl'.
  # An example 'backend.hcl' template is intentionally NOT committed so each
  # environment supplies its own bucket / state key / lock table out-of-band.
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.tags,
      {
        Environment = var.environment
        Project     = var.project_name
        ManagedBy   = "terraform"
      }
    )
  }
}
