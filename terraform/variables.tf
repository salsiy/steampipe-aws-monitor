variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID where ECS tasks will run"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ECS tasks (use public subnets or private subnets with NAT Gateway)"
  type        = list(string)
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "steampipe-aws-monitor"
}

variable "slack_workspace_id" {
  description = "Slack workspace ID from AWS Chatbot Console"
  type        = string
}

variable "slack_channel_id" {
  description = "Slack channel ID from Slack"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "steampipe-aws-monitor"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
