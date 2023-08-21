FROM public.ecr.aws/lambda/python:3.9

RUN pip install -U pip
COPY [ "requirements.txt", "./" ]
RUN pip install -r requirements.txt

COPY [ "predict-stocks/src/predict_lambda/index.py", "./" ]
COPY [ "predict-stocks/src/DataFetcher.py", "./" ]

CMD [ "index.lambda_handler" ]