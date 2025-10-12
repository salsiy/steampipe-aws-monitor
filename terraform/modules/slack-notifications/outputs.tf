output "chatbot_configuration_arn" {
  description = "ARN of the Chatbot configuration"
  value       = aws_chatbot_slack_channel_configuration.main.chat_configuration_arn
}
