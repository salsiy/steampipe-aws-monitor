
output "ecr_repository_url" {
  description = "ECR repository URL - use for docker push"
  value       = module.ecs_monitor.ecr_repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs_monitor.cluster_name
}

output "task_definition_arn" {
  description = "ECS task definition ARN"
  value       = module.ecs_monitor.task_definition_arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group"
  value       = module.ecs_monitor.log_group_name
}

output "sns_topic_arn" {
  description = "SNS topic ARN"
  value       = module.sns.sns_topic_arn
}

output "docker_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${module.ecs_monitor.ecr_repository_url}"
}

output "docker_build_push_commands" {
  description = "Commands to build and push Docker image"
  value       = <<-EOT
    docker build --platform linux/amd64 -t ${var.project_name} .
    
    docker tag ${var.project_name}:latest ${module.ecs_monitor.ecr_repository_url}:latest
    
    docker push ${module.ecs_monitor.ecr_repository_url}:latest
  EOT
}

output "run_task_command" {
  description = "Command to manually trigger the ECS task"
  value       = <<-EOT
    aws ecs run-task \
      --cluster ${module.ecs_monitor.cluster_name} \
      --task-definition ${module.ecs_monitor.task_definition_arn} \
      --launch-type FARGATE \
      --network-configuration "awsvpcConfiguration={subnets=[${join(",", var.subnet_ids)}],securityGroups=[${module.networking.security_group_id}],assignPublicIp=ENABLED}" \
      --region ${var.aws_region}
  EOT
}

output "view_logs_command" {
  description = "Command to view CloudWatch logs"
  value       = "aws logs tail ${module.ecs_monitor.log_group_name} --follow --region ${var.aws_region}"
}

