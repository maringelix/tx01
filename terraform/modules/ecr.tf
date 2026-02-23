# ECR Repository
resource "aws_ecr_repository" "main" {
  name                 = "dx01-app"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = var.environment == "stg" ? true : false

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-ecr-${var.environment}"
  }
}

# ECR Lifecycle Policy (keep only last 10 images)
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name
  policy     = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images older than 7 days"
        selection = {
          tagStatus           = "untagged"
          countType           = "sinceImagePushed"
          countUnit           = "days"
          countNumber         = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Outputs
output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.main.repository_url
}

output "ecr_repository_arn" {
  description = "ECR Repository ARN"
  value       = aws_ecr_repository.main.arn
}
