variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "ecr_arn" {
  description = "ECR repository ARN — used to scope the GitHub Actions push policy"
  type        = string
}