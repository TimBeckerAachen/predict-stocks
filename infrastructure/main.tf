# Make sure to create state bucket beforehand
terraform {
  required_version = ">= 1.0"
  backend "s3" {
    bucket  = "terraform-states-cloud"
    key     = "state"
    region  = "eu-west-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current_identity" {}

locals {
  account_id = data.aws_caller_identity.current_identity.account_id
  common_tags = {
    project = var.project_id
    owner = var.owner
  }
}

module "s3_bucket" {
  source = "./modules/s3"
  model_bucket = "${var.model_bucket}-${var.project_id}"
}

module "lambda_function" {
  source = "./modules/lambda"
  image_uri = module.ecr_image.image_uri
  lambda_function_name = "${var.lambda_function_name}_${var.project_id}"
  lambda_schedule = var.lambda_schedule
  model_bucket = module.s3_bucket.name
  prefect_api_key = var.prefect_api_key
  prefect_api_url = var.prefect_api_url
  ticker = var.ticker
  model_dir = var.model_dir
}

module "ecr_image" {
   source = "./modules/ecr"
   ecr_repo_name = "${var.ecr_repo_name}_${var.project_id}"
   account_id = local.account_id
   lambda_function_local_path = var.lambda_function_local_path
   docker_image_local_path = var.docker_image_local_path
   region = var.aws_region
}

output "lambda_function" {
  value     = "${var.lambda_function_name}_${var.project_id}"
}

output "model_bucket" {
  value = module.s3_bucket.name
}
