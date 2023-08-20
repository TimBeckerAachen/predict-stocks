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

locals {
  layer_zip_path    = "prefect_layer.zip"
  layer_name        = "prefect_lambda_layer"
  requirements_path = "${path.root}../../../requirements-prefect.txt"
}

resource "null_resource" "prefect_lambda_layer" {
  triggers = {
    requirements = filesha1(local.requirements_path)
  }
  # the command to install python and dependencies to the machine and zips
  provisioner "local-exec" {
    command = <<EOF
      rm -rf package
      mkdir package
      pip install --target package/ -r local.requirements_path
      zip -r ${local.layer_zip_path} python/
    EOF
  }
}

resource "aws_s3_bucket" "lambda_layer_bucket" {
  bucket = "lambda-layer-bucket"
}

resource "aws_s3_object" "lambda_layer_zip" {
  bucket     = aws_s3_bucket.lambda_layer_bucket.id
  key        = "lambda_layers/${local.layer_name}/${local.layer_zip_path}"
  source     = local.layer_zip_path
  depends_on = [null_resource.prefect_lambda_layer]
}

resource "aws_lambda_layer_version" "prefect_lambda_layer" {
  s3_bucket           = aws_s3_bucket.lambda_layer_bucket.id
  s3_key              = aws_s3_object.lambda_layer_zip.key
  layer_name          = local.layer_name
  compatible_runtimes = ["python3.8"]
  skip_destroy        = false
  depends_on          = [aws_s3_object.lambda_layer_zip]
}

data "archive_file" "lambda_function_zip" {
  type = "zip"
  source_file = "${var.lambda_function_local_path}/index.py"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "predict_lambda" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.iam_lambda.arn

  description = "lambda for making predictions"
  handler     = "index.lambda_handler"
  runtime     = "python3.8"
  timeout     = 180

  filename = data.archive_file.lambda_function_zip.output_path
  layers = [aws_lambda_layer_version.prefect_lambda_layer.arn]

  environment {
    variables = {
      MODEL_BUCKET = var.model_bucket
      PREFECT_HOME = "/tmp/.prefect"
      PREFECT_API_KEY = var.prefect_api_key
      PREFECT_API_URL = var.prefect_api_url
    }
  }

}