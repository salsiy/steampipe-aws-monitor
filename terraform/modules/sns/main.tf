
resource "aws_sns_topic" "notifications" {
  name         = "${var.project_name}-reports"
  display_name = "Steampipe AWS Monitor Reports"
}

resource "aws_sns_topic_policy" "notifications" {
  arn = aws_sns_topic.notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid = "AllowServices"
      Effect = "Allow"
      Principal = {
        Service = ["events.amazonaws.com", "ecs-tasks.amazonaws.com"]
      }
      Action   = "SNS:Publish"
      Resource = aws_sns_topic.notifications.arn
    }]
  })
}


