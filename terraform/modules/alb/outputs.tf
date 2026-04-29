output "alb_dns_name" {
  description = "Public DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "Target group ARN passed to ECS service"
  value       = aws_lb_target_group.main.arn
}