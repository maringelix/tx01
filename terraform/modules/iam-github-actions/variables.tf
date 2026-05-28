variable "github_repository" {
  type        = string
  description = "GitHub repository in 'owner/repo' format that may assume the role."
  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repository))
    error_message = "github_repository must be in 'owner/repo' format."
  }
}

variable "allowed_refs" {
  type        = list(string)
  description = "List of OIDC 'sub' suffixes that may assume the role. Examples: 'ref:refs/heads/main', 'environment:prd', 'pull_request'."
  default     = ["ref:refs/heads/main"]
  validation {
    condition     = length(var.allowed_refs) > 0
    error_message = "allowed_refs must contain at least one entry; refusing to create a wildcard trust policy."
  }
}

variable "role_name" {
  type        = string
  description = "Name of the IAM role to create."
  validation {
    condition     = can(regex("^[A-Za-z0-9+=,.@_-]{1,64}$", var.role_name))
    error_message = "role_name must match IAM role naming rules (max 64 chars)."
  }
}

variable "managed_policy_arns" {
  type        = list(string)
  description = "List of IAM managed policy ARNs to attach to the role."
  default     = []
}

variable "max_session_duration" {
  type        = number
  description = "Maximum session duration in seconds (between 3600 and 43200)."
  default     = 3600
  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 (1h) and 43200 (12h)."
  }
}

variable "create_oidc_provider" {
  type        = bool
  description = "Create the GitHub OIDC provider in this account. Set to false if another module already created it."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to created resources."
  default     = {}
}
