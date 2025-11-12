locals {
  cloudtrail_name = "rp-account-security-trail"

  cloudtrail_source_arn = "arn:aws:cloudtrail:${var.aws_region}:${var.account_id}:trail/${local.cloudtrail_name}"
}