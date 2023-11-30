#-----------------------
# Geocoding
#-----------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# -----------------------
# VARIABLES SECTION - PLEASE UPDATE TO MATCH YOUR ENVIRONMENT
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable s3_precode_prefix {
  description = "S3 prefix"
  type        = string
  default     = "pre_geocode"
}

variable s3_postcode_prefix {
  description = "S3 prefix"
  type        = string
  default     = "post_geocode"
}

# END OF VARIABLES SECTION
# -----------------------

provider "aws" {
  region = var.aws_region
}

module "location" {
  source = "./modules/location"
}

module "lambdas" {
  source        = "./modules/lambdas"
  sqs_queue_arn = module.sqs.sqs_queue_arn
  sqs_queue_url = module.sqs.sqs_queue_url
  index_name    = module.location.index_name
  s3_bucket_name = module.s3.s3_bucket_name
  s3_postcode_prefix = var.s3_postcode_prefix
}

module "sqs" {
  source = "./modules/sqs"
}

module "s3" {
  source                = "./modules/s3"
  batcher_function_name = module.lambdas.batcher_function_name
  batcher_function_arn  = module.lambdas.batcher_function_arn
  s3_precode_prefix = var.s3_precode_prefix
}