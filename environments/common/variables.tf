variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "eu-west-1"
}

variable "account_id" {
  description = "The ID of the AWS account"
  type        = string
}

variable "notification_emails" {
  description = "A list of email addresses to receive budget alerts."
  type        = list(string)
}