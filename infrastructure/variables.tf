variable "aws_region" {
  description = "AWS region to create resources"
  default     = "eu-west-1"
}

variable "project_id" {
  description = "project_id"
  default = "predict-stocks"
}

variable "model_bucket" {
  description = "s3_bucket"
  default = "bucket"
}

variable "lambda_function_local_path" {
  description = ""
}

variable "lambda_function_name" {
  description = ""
}
variable "owner" {
  description = "name of who maintains the project"
}