resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.model_bucket
  force_destroy = true
}

output "name" {
  value = aws_s3_bucket.s3_bucket.bucket
}