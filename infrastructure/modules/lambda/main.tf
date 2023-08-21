data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_lambda" {
  name               = "iam_${var.lambda_function_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "allow_logging_document" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "allow_logging" {
  name        = "lambda_logging_${var.lambda_function_name}"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.allow_logging_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_lambda.name
  policy_arn = aws_iam_policy.allow_logging.arn
}

resource "aws_iam_policy" "allow_s3" {
  name        = "lambda_s3_${var.lambda_function_name}"
  description = "IAM policy for allowing a lambda access to s3"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListAllMyBuckets",
        "s3:GetBucketLocation",
        "s3:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${var.model_bucket}",
        "arn:aws:s3:::${var.model_bucket}/*"
      ]
    },
    {
      "Action": [
        "autoscaling:Describe*",
        "cloudwatch:*",
        "logs:*",
        "sns:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.iam_lambda.name
  policy_arn = aws_iam_policy.allow_s3.arn
}

resource "aws_cloudwatch_event_rule" "predict_daily_rule" {
  name                = "predict_daily"
  description         = "rule to trigger prediction lambda every day at 15.00"
  schedule_expression = var.lambda_schedule
}

resource "aws_cloudwatch_event_target" "predict_daily_target" {
  rule      = aws_cloudwatch_event_rule.predict_daily_rule.name
  target_id = "lambda"
  arn       = aws_lambda_function.predict_lambda.arn
}

resource "aws_lambda_permission" "allow_event_to_call_lambda" {
  statement_id  = "AllowScheduledLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.predict_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.predict_daily_rule.arn
}

resource "aws_lambda_function" "predict_lambda" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.iam_lambda.arn

  description = "lambda for making predictions"
  image_uri = var.image_uri
  package_type = "Image"
  timeout     = 240
  memory_size = 1024

  environment {
    variables = {
      MODEL_BUCKET = var.model_bucket
      MODEL_DIR = var.model_dir
      TICKER = var.ticker
      PREFECT_HOME = "/tmp/.prefect"
      PREFECT_API_KEY = var.prefect_api_key
      PREFECT_API_URL = var.prefect_api_url
    }
  }

}