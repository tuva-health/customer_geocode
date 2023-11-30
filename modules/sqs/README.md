## SQS module

This module creates the SQS queue for geocoding. The batcher Lambda will populate
this queue with messages each with 100 addresses. The geocoding Lambda is subscribed
to this queue and will process the messages through Amazon Location Service and 
write the results to S3. 