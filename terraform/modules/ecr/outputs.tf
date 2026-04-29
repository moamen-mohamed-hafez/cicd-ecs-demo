output "repository_url" {
  description = "ECR repository URL for Docker push"
  value       = aws_ecr_repository.main.repository_url
}

output "repository_arn" {
  description = "ECR repository ARN for IAM policies"
  value       = aws_ecr_repository.main.arn
}

output "repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.main.name
}