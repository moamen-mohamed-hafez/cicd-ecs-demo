output "task_execution_role_arn" {
  description = "ECS Task Execution Role ARN"
  value       = aws_iam_role.task_execution.arn
}

output "task_role_arn" {
  description = "ECS Task Role ARN (app permissions)"
  value       = aws_iam_role.task_role.arn
}

output "github_actions_role_arn" {
  description = "Paste this as AWS_ROLE_ARN secret in GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}