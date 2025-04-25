output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.serverless_deployer.repository_url
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket for serverless configuration"
  value       = aws_s3_bucket.serverless_config.id
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.serverless_deployment_cluster.name
}

output "task_definition_arn" {
  description = "The ARN of the task definition"
  value       = aws_ecs_task_definition.serverless_deployer.arn
}

output "subnet_id" {
  description = "The ID of the subnet for the ECS task"
  value       = aws_subnet.public_subnet.id
}

output "security_group_id" {
  description = "The ID of the security group for the ECS task"
  value       = aws_security_group.ecs_sg.id
}
