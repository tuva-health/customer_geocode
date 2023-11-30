variable "sqs_queue_arn" {
  description = "The ARN of the SQS queue"
  type        = string
}

variable "sqs_queue_url" {
  description = "The URL of the SQS queue"
  type        = string
}

variable "index_name" {
  description = "The location index name"
  type        = string
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "s3_postcode_prefix" {
  description = "The prefix of the S3 bucket"
  type        = string
}

data "archive_file" "lambda_sqs_zip" {
  type        = "zip"
  source_file = "${path.module}/geocode-sqs.py"
  output_path = "${path.module}/geocode-sqs.zip"
}

data "archive_file" "lambda_batcher_zip" {
  type        = "zip"
  source_file = "${path.module}/addressbatcher.py"
  output_path = "${path.module}/addressbatcher.zip"
}

resource "aws_iam_role" "lambda_exec_role_geocode" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = ["lambda.amazonaws.com"],
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_exec_policy" {
  name        = "lambda_exec_policy"
  description = "Policy for allowing lambda function to search place index for text"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "geo:SearchPlaceIndexForText",
          "s3:GetObject",
          "s3:PutObject",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:SendMessage",
          "sqs:ReceiveMessage"         
        ]
        Resource = "*" # Modify this to restrict access to specific resources
        Effect   = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_role_policy" {
  role       = aws_iam_role.lambda_exec_role_geocode.name
  policy_arn = aws_iam_policy.lambda_exec_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role_geocode.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "geocode_lambda_sqs" {
  filename      = data.archive_file.lambda_sqs_zip.output_path
  function_name = "geocode_addresses_sqs"
  role          = aws_iam_role.lambda_exec_role_geocode.arn
  handler       = "geocode-sqs.lambda_handler" # update if your file/handler is different

  source_code_hash = data.archive_file.lambda_sqs_zip.output_base64sha256

  runtime = "python3.8" # update to match your python version

  timeout = 900

  reserved_concurrent_executions = 2

  environment {
    variables = {
      PLACE_INDEX = var.index_name
      S3_BUCKET_NAME = var.s3_bucket_name
      S3_POSTCODE_PREFIX = var.s3_postcode_prefix
    }
  }
}

resource "aws_lambda_function" "address-batcher" {
  filename      = data.archive_file.lambda_batcher_zip.output_path
  function_name = "geocode-address-batcher"
  role          = aws_iam_role.lambda_exec_role_geocode.arn
  handler       = "addressbatcher.lambda_handler" # update if your file/handler is different

  source_code_hash = data.archive_file.lambda_batcher_zip.output_base64sha256

  runtime = "python3.8" # update to match your python version

  timeout = 900

  environment {
    variables = {
      QUEUE_URL = var.sqs_queue_url
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.geocode_lambda_sqs.function_name
}

output "batcher_function_name" {
  description = "The function name of the batcher lambda"
  value = aws_lambda_function.address-batcher.function_name
}

output "batcher_function_arn" {
  description = "The ARN of the batcher lambda"
  value = aws_lambda_function.address-batcher.arn
}