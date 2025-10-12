
resource "aws_iam_role" "chatbot" {
  name = var.chatbot_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "chatbot.amazonaws.com"
      }
    }]
  })

}

resource "aws_iam_policy" "chatbot" {
  name        = "${var.project_name}-chatbot"
  description = "Policy for AWS Chatbot to access CloudWatch Logs and S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:GetLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "${var.log_group_arn}:*"
      },
    ]
  })

}

resource "aws_iam_role_policy_attachment" "chatbot" {
  role       = aws_iam_role.chatbot.name
  policy_arn = aws_iam_policy.chatbot.arn
}

resource "aws_chatbot_slack_channel_configuration" "main" {
  configuration_name = var.chatbot_configuration_name
  iam_role_arn      = aws_iam_role.chatbot.arn
  slack_channel_id  = var.slack_channel_id
  slack_team_id     = var.slack_workspace_id
  
  sns_topic_arns = [var.sns_topic_arn]

  guardrail_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]

  logging_level = "INFO"
  
}

resource "aws_cloudwatch_event_rule" "task_completion" {
  name        = "${var.project_name}-task-completion"
  description = "Trigger notification when ECS task completes"

  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Task State Change"]
    detail = {
      clusterArn        = [var.cluster_arn]
      lastStatus        = ["STOPPED"]
      stopCode          = ["EssentialContainerExited"]
      taskDefinitionArn = [var.task_definition_arn]
    }
  })

}

resource "aws_cloudwatch_event_target" "completion_notification" {
  rule      = aws_cloudwatch_event_rule.task_completion.name
  target_id = "SendToSNS"
  arn       = var.sns_topic_arn

  input_transformer {
    input_paths = {
      taskArn   = "$.detail.taskArn"
      stoppedAt = "$.detail.stoppedAt"
      exitCode  = "$.detail.containers[0].exitCode"
    }
    input_template = <<-EOT
{
  "version": "1.0",
  "source": "custom",
  "content": {
    "textType": "client-markdown",
    "title": "Steampipe ECS Monitor Completed",
    "description": "**Status:** Completed\n**Timestamp:** <stoppedAt>\n**Exit Code:** <exitCode>\n\n**CloudWatch Logs:** ${var.log_group_name}"
  },
  "metadata": {
    "summary": "ECS monitoring scan completed"
  }
}
EOT
  }
}

