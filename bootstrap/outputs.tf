output "tf_state_bucket_name" {
  description = "The name of the S3 bucket created for Terraform remote state."
  value       = aws_s3_bucket.tf_state_bucket.id
}