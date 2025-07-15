# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.chronicle_vpc.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.chronicle_vpc.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private_subnets[*].id
}

# Load Balancer Outputs
output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.chronicle_alb.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.chronicle_alb.zone_id
}

output "load_balancer_url" {
  description = "URL of the load balancer"
  value       = "http://${aws_lb.chronicle_alb.dns_name}"
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.chronicle_cluster.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.chronicle_service.name
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.chronicle_task.arn
}

# ECR Outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.chronicle_repo.repository_url
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.chronicle_repo.name
}

# EFS Outputs
output "efs_file_system_id" {
  description = "ID of the EFS file system"
  value       = aws_efs_file_system.chronicle_efs.id
}

output "efs_access_point_id" {
  description = "ID of the EFS access point"
  value       = aws_efs_access_point.chronicle_access_point.id
}

# CloudWatch Outputs
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.chronicle_logs.name
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ID of the ECS security group"
  value       = aws_security_group.ecs_tasks.id
}

output "efs_security_group_id" {
  description = "ID of the EFS security group"
  value       = aws_security_group.efs.id
}

# IAM Outputs
output "ecs_execution_role_arn" {
  description = "ARN of the ECS execution role"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

# Application URLs
output "application_endpoints" {
  description = "Application endpoints"
  value = {
    load_balancer = "http://${aws_lb.chronicle_alb.dns_name}"
    health_check  = "http://${aws_lb.chronicle_alb.dns_name}${var.health_check_path}"
  }
}

# Deployment Information
output "deployment_info" {
  description = "Deployment information"
  value = {
    region             = var.aws_region
    environment        = var.environment
    project_name       = var.project_name
    ecs_cluster        = aws_ecs_cluster.chronicle_cluster.name
    ecs_service        = aws_ecs_service.chronicle_service.name
    ecr_repository     = aws_ecr_repository.chronicle_repo.repository_url
    log_group          = aws_cloudwatch_log_group.chronicle_logs.name
  }
}