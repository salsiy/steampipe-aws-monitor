
resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

}

resource "aws_iam_policy" "aws_readonly" {
  name        = "${var.project_name}-readonly"
  description = "Read-only access to AWS resources for Steampipe queries"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecs:Describe*",
        "ecs:List*",
        "ec2:Describe*",
        "rds:Describe*",
        "s3:ListAllMyBuckets",
        "s3:GetBucket*",
        "iam:Get*",
        "iam:List*",
        "elasticloadbalancing:Describe*",
        "cloudformation:Describe*",
        "ce:Get*"
      ]
      Resource = "*"
    }]
  })

}

resource "aws_iam_policy" "sns_publish" {
  name        = "${var.project_name}-sns-publish"
  description = "Publish to SNS topics for Slack notifications"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = "arn:aws:sns:*:*:${var.project_name}-*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "task_readonly" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.aws_readonly.arn
}

resource "aws_iam_role_policy_attachment" "task_sns" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.sns_publish.arn
}

resource "aws_iam_role" "eventbridge" {
  name = "${var.project_name}-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
    }]
  })

}

resource "aws_iam_policy" "eventbridge" {
  name        = "${var.project_name}-eventbridge"
  description = "Policy for EventBridge to run ECS tasks"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecs:RunTask"
        Resource = "arn:aws:ecs:*:*:task-definition/${var.project_name}*"
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          aws_iam_role.ecs_execution.arn,
          aws_iam_role.ecs_task.arn
        ]
      }
    ]
  })

}

resource "aws_iam_role_policy_attachment" "eventbridge" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.eventbridge.arn
}

