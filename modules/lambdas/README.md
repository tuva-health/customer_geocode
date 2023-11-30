## Lambdas module

This module creates several Lambdas for geocoding. 

Lambdas: 
- addressbatcher - this takes a CSV file of addresses as input and creates batches of 100 address and puts them in the SQS queue
  - this is automatically triggered by an S3 event defined in the `s3` module
  - the SQS queue destination is defined in the `sqs` module
- geocode-sqs - this Lambda processes address from the SQS queue and writes results to S3
