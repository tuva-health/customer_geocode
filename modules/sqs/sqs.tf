resource "aws_sqs_queue" "geocode_queue" {
  name = "geocodeQueue"
  delay_seconds = 0
  message_retention_seconds = 345600
  visibility_timeout_seconds = 1000
}

output "sqs_queue_arn" {
  description = "The ARN of the SQS queue"
  value       = aws_sqs_queue.geocode_queue.arn
}

output "sqs_queue_url" {
  description = "The URL of the SQS queue"
  value = aws_sqs_queue.geocode_queue.url
}