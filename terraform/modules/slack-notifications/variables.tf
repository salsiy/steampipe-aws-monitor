variable "project_name" {
  description = "Project name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic"
  type        = string
}

variable "chatbot_role_name" {
  description = "Name of the Chatbot IAM role"
  type        = string
}

variable "chatbot_configuration_name" {
  description = "Name of the Chatbot configuration"
  type        = string
}

variable "slack_workspace_id" {
  description = "Slack workspace/team ID"
  type        = string
}

variable "slack_channel_id" {
  description = "Slack channel ID"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster"
  type        = string
}

variable "task_definition_arn" {
  description = "ARN of the ECS task definition"
  type        = string
}

variable "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  type        = string
}

variable "log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
}
