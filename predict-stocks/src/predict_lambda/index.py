"""Python AWS Lambda Hello World Example
   This example Lambda function will simply return 'Hello from Lambda!' and
   a HTTP Status Code 200.
"""

import json
from prefect import flow, get_run_logger


@flow(name='demo')
def fct():
    logger = get_run_logger()
    logger.warning('test')
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }


def lambda_handler(event, context):
    return fct()

