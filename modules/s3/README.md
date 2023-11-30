## S3 module

This module creates an S3 trigger when a new file is created that kicks off the 
geocoding pipeline. 

If you have an existing bucket update the `bucket` value with the name. 

If you need to create a bucket uncomment the bucket resource and comment out the
the data resource. 

You also need to customize the `filter_prefix` in the notification resource. 

The trigger will start the batching Lambda created in the `lambdas` module which 
populates the SQS queue and runs the geocoding Lambda. 
