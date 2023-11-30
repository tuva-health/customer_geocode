## Geocoding in AWS

This repository contains the AWS infrastructure code for 
setting up geocoding. 

All IaC is written in Terraform.

**Please modify backend.tf to point to your desired state storage.** 

**Before executing this repo update the variables section in `main.tf`**

**In modules/s3/triggers.tf you need to either input your bucket name in data 
element for existing buckets or comment that out and uncomment the bucket 
creation statement. Based on which you choose there are 2 other lines that need
to be updated, one in `resource "aws_lambda_permission" "allow_bucket"` and 
one in `resource "aws_s3_bucket_notification" "geocode_notification"`. 
Comment out the one you don't need and uncomment the one you do, they are labeled.**


Each module has a README that details what functions are available. 
The README will also contain any notes on any manual steps required 
outside the Terraform code. 

Current modules: 
- lambdas - several geocoding functions
- location - used for geocoding service
- s3 - triggers for automating geocoding pipeline
- sqs - geocoding queues

Remember to run `terraform init` to enable the modules and cloud connection. 
