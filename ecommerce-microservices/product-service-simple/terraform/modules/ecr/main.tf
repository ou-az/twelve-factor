resource "aws_ecr_repository" "app" {
  name                 = lower("${var.name_prefix}")
  image_tag_mutability = "MUTABLE"  # Allow overwriting tags
  
  image_scanning_configuration {
    scan_on_push = true  # Security best practice: scan images for vulnerabilities
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-ecr-repo"
    }
  )
}

# ECR Lifecycle Policy to ensure we don't accumulate too many unused images
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep only the last 5 untagged images",
        selection = {
          tagStatus   = "untagged",
          countType   = "imageCountMoreThan",
          countNumber = 5
        },
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2,
        description  = "Keep only the last 10 tagged images",
        selection = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = 10
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}
