# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
# https://github.com/aws-samples/amazon-location-samples/blob/main/geocode-udf-lambda-redshift/Lambda/geocode.py

import boto3
import botocore
import botocore.exceptions
import json
import logging
import os
import time

index_name = os.environ["PLACE_INDEX"]
S3_BUCKET_NAME = os.environ["S3_BUCKET_NAME"]
S3_POSTCODE_PREFIX = os.environ["S3_POSTCODE_PREFIX"]

logger = logging.getLogger()
logger.setLevel(logging.INFO)

location = boto3.client("location")

s3_client = boto3.client('s3')


def lambda_handler(event, context):

    logger.debug (event)

    try:
        response = dict()

        for record in event['Records']:

            results = []

            message = json.loads(record['body'])
            message_id = record['messageId']
            logger.info ("Record Count: %d" % len(message))

            t1 = time.time()

            for address in message:
                logger.debug(address)
                patient_id, address_line, municipality_name, state_code, post_code = \
                    address['PATIENT_ID'], address['ADDRESS'], address['CITY'], address['STATE'], address['ZIP_CODE']
                try:
                    results.append(json.dumps(geocode_address(patient_id, address_line, municipality_name, state_code,
                                                              post_code)))
                except:
                    results.append(None)

            t2 = time.time()

            logger.info ("Result Count: %d Time: %.3f" % (len(results), t2 - t1))

            # Convert to single json object per line for Glue crawling
            results = [json.loads(result) for result in results]
            results_string = '\n'.join(json.dumps(result) for result in results)

            try: 
                s3_client.put_object(
                    Bucket=S3_BUCKET_NAME,
                    Key=f'{S3_POSTCODE_PREFIX}/{message_id}.json',
                    Body=results_string
                )
            except Exception as e: 
                response['success'] = False
                response['error_msg'] = str(e)                

        response['success'] = True
        response['results'] = results
    except Exception as e:
        response['success'] = False
        response['error_msg'] = str(e)

    logger.debug (response)

    return

def geocode_address(patient_id, address_line, municipality_name, state_code, post_code):
    max_retries = 5
    retry_delay = 1  # Initial delay in seconds

    for attempt in range(max_retries):
        try:
            # Validate input
            if address_line == "":
                raise ValueError("Missing address line")

            if municipality_name == "":
                raise ValueError("Missing municipality name")

            if state_code == "None":
                state_code = ""

            if post_code == "None":
                post_code = ""

            # Construct geocoding request
            text = ("%s, %s %s %s" % (address_line, municipality_name, state_code, post_code))
            response = location.search_place_index_for_text(IndexName=index_name, Text=text)

            # Process response
            data = response["Results"]
            if len(data) >= 1:
                point = data[0]["Place"]["Geometry"]["Point"]
                label = data[0]["Place"]["Label"]
                logger.debug ("Match: [%s,%s] %s" % (point[0], point[1], label))

                response = {
                    "Patient_id": patient_id,
                    "Longitude": point[0],
                    "Latitude": point[1],
                    "Label": label,
                    "MultipleMatch": len(data) > 1
                }
            else:
                logger.debug ("No geocoding results found")
                response = {"Error": "No geocoding results found"}

            return response  # Return response on successful execution

        except botocore.exceptions.ClientError as error:
            if error.response['Error']['Code'] in ["ThrottlingException", "RequestLimitExceeded"]:
                logger.info(f"Rate limit exceeded, retrying in {retry_delay} seconds...")
                time.sleep(retry_delay)
                retry_delay *= 2  # Double the delay for the next retry
            else:
                raise  # Re-raise the exception for any other ClientError

        except Exception as e:
            logger.exception(e)
            response = {"Exception": str(e)}
            return response

    # Handling the case where all retries fail
    logger.error("Max retries reached. Failed to geocode address.")
    return {"Error": "Max retries reached"}