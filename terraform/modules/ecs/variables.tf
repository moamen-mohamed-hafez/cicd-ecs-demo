variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from networking module"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where ECS tasks run"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "ecr_image_url" {
  description = "ECR repository URL for the container image"
  type        = string
}

variable "alb_target_group_arn" {
  description = "ALB target group ARN for load balancer attachment"
  type        = string
}

variable "task_execution_role" {
  description = "IAM role ARN for ECS task execution (ECR pull, CloudWatch logs)"
  type        = string
}

variable "task_role_arn" {
  description = "IAM role ARN for the running container (app permissions)"
  type        = string
}

variable "app_port" {
  description = "Port the container listens on"
  type        = number
}

variable "cpu" {
  description = "Fargate task CPU units"
  type        = number
}

variable "memory" {
  description = "Fargate task memory in MiB"
  type        = number
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
}