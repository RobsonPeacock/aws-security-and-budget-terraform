module "foundational_security" {
  source     = "../../modules/security"
  account_id = local.account_id
  aws_region = var.aws_region
}

module "foundational_budget" {
  source              = "../../modules/budget"
  account_id          = local.account_id
  notification_emails = var.notification_emails
}