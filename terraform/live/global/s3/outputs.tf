output "state_bucket_name" {
  value       = aws_s3_bucket.terraform_state.bucket
  description = "The Name of the S3 bucket"
}