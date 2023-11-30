# uncomment this if you need to create the bucket, otherwise assign your bucket
resource "aws_s3_bucket" "geocode-data" {
  bucket = "geocoding-bucket"  # replace with your bucket name
}

# comment this out if you create a bucket above
#data "aws_s3_bucket" "geocode-data" {
#  bucket = "geocoding-bucket"  # replace with your existing bucket name
#}

variable "s3_precode_prefix" {
    description = "The prefix for the pre-geocode data"
    type        = string
}

variable "batcher_function_name" {
  description = "The function name of the batcher lambda"
  type        = string
}

variable "batcher_function_arn" {
  description = "The ARN of the batcher lambda"
  type        = string
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = var.batcher_function_name
  principal     = "s3.amazonaws.com"
  #source_arn    = data.aws_s3_bucket.geocode-data.arn  # uncomment this if you reference a bucket above
  source_arn    = aws_s3_bucket.geocode-data.arn  # uncomment this if you create a bucket above
}

resource "aws_s3_bucket_notification" "geocode_notification" {
  #bucket = data.aws_s3_bucket.geocode-data.bucket  # uncomment this if you reference a bucket above
  bucket = aws_s3_bucket.geocode-data.bucket  # uncomment this if you create a bucket above

  lambda_function {
    lambda_function_arn = var.batcher_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "var.s3_precode_prefix"
  }
}

output "s3_bucket_name" {
  value = aws_s3_bucket.geocode-data.bucket
}
