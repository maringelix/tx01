variable "bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "tx01-terraform-state-maringelix-2025"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "tx01"
    Environment = "bootstrap"
    ManagedBy   = "Terraform"
  }
}

variable "force_destroy" {
  description = "Allow deleting non-empty bucket (useful for testing). Set to false in production."
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Enable S3 versioning for state bucket"
  type        = bool
  default     = true
}
