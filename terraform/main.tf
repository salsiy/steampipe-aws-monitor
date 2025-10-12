terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = var.tags
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "networking" {
  source = "./modules/networking"
  
  vpc_id       = var.vpc_id
  project_name = var.project_name
}

module "iam" {
  source = "./modules/iam"
  
  project_name = var.project_name
}

module "sns" {
  source = "./modules/sns"
  
  project_name = var.project_name
}

module "ecs_monitor" {
  source = "./modules/ecs-monitor"
  depends_on = [module.iam]
  
  project_name         = var.project_name
  aws_region           = data.aws_region.current.name
  ecr_repository_name  = var.project_name
  cluster_name         = "${var.project_name}-cluster"
  task_family          = var.project_name
  container_name       = var.project_name
  execution_role_arn   = module.iam.ecs_execution_role_arn
  task_role_arn        = module.iam.ecs_task_role_arn
  eventbridge_role_arn = module.iam.eventbridge_role_arn
  log_group_name       = "/ecs/${var.project_name}"
  subnet_ids           = var.subnet_ids
  security_group_ids   = [module.networking.security_group_id]
  sns_topic_arn        = module.sns.sns_topic_arn
}

module "slack_notifications" {
  source = "./modules/slack-notifications"
  depends_on = [module.ecs_monitor]
  
  project_name               = var.project_name
  aws_region                 = data.aws_region.current.name
  sns_topic_arn              = module.sns.sns_topic_arn
  chatbot_role_name          = "${var.project_name}-chatbot-role"
  chatbot_configuration_name = "${var.project_name}-slack-v2"
  slack_workspace_id         = var.slack_workspace_id
  slack_channel_id           = var.slack_channel_id
  task_role_arn              = module.iam.ecs_task_role_arn
  cluster_arn                = module.ecs_monitor.cluster_arn
  task_definition_arn        = module.ecs_monitor.task_definition_arn
  log_group_arn              = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${module.ecs_monitor.log_group_name}"
  log_group_name             = module.ecs_monitor.log_group_name
}
