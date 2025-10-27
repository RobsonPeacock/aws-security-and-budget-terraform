terraform {
  backend "s3" {
    bucket           = var.tf_state_bucket_name
    key              = "aws-security-and-budget-terraform/common.tfstate"
    region           = var.aws_region
    tf-state-locking = "tf-state-locking"
    encrypt          = true
  }
}