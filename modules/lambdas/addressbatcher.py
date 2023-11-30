# lambda s3 trigger batcher
import boto3
import json
import csv
import os

sqs = boto3.client('sqs')
s3 = boto3.client('s3')
queue_url = os.environ.get("QUEUE_URL")  # SQS Queue URL must be set in Lambda environment variables


def lambda_handler(event, context):
    # Get bucket and file key from the S3 event
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    # Download file from S3
    response = s3.get_object(Bucket=bucket_name, Key=key)
    data = response['Body'].read().decode('utf-8').splitlines()

    # Convert CSV data to list of dictionaries
    addresses = list(csv.DictReader(data))
    total_records = len(addresses)
    print(f"Total Records: {total_records}")

    # Split list into chunks of 100
    chunks = [addresses[x:x + 100] for x in range(0, total_records, 100)]

    for chunk in chunks:
        # Convert the chunk to json and send it as a message in SQS
        sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(chunk)
        )
    return {
        'statusCode': 200,
        'body': json.dumps('Messages sent to SQS successfully!')
    }