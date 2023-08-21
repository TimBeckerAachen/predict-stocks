"""Python AWS Lambda Hello World Example
   This example Lambda function will simply return 'Hello from Lambda!' and
   a HTTP Status Code 200.
"""

import os
import json
import boto3
import mlflow.sklearn
from prefect import flow, get_run_logger

from DataFetcher import DataFetcher


LOCAL_MODEL_PATH = '/tmp/local_model_dir'


def fetch_model(bucket_name: str,
                model_dir: str
                ) -> None:

    s3 = boto3.client('s3')
    bucket_name = bucket_name
    model_dir = model_dir

    files = ['conda.yaml', 'MLmodel', 'model.pkl', 'python_env.yaml', 'requirements.txt']

    local_model_dir = LOCAL_MODEL_PATH
    if not os.path.exists(local_model_dir):
        os.makedirs(local_model_dir)

    for file in files:
        local_path = os.path.join(local_model_dir, file)
        s3_path = os.path.join(model_dir, file)
        s3.download_file(bucket_name, s3_path, local_path)


@flow(name='stock-prediction')
def predict() -> float:
    logger = get_run_logger()
    bucket = os.getenv('MODEL_BUCKET')
    model_dir = os.getenv('MODEL_DIR')
    ticker = os.getenv('TICKER')
    logger.info('start prediction')

    fetch_model(bucket, model_dir)
    model = mlflow.sklearn.load_model(model_uri=LOCAL_MODEL_PATH)
    fetcher = DataFetcher()
    pred_data = fetcher.fetch_latest_prices(ticker)
    prediction = model.predict(pred_data.reshape(1, -1))[0]

    logger.info(f'The model predict a stock closing price for {ticker} of {prediction}')

    return prediction


def lambda_handler(event, context):
    prediction = predict()
    return {
        'statusCode': 200,
        'body': json.dumps(prediction)
    }
