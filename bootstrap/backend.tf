terraform {
  backend "s3" {
    bucket         = "robson-aws-security-budget-tfstate-12345"
    key            = "aws-security-and-budget-terraform/bootstrap/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "tf-state-locking"
    encrypt        = true
  }
}