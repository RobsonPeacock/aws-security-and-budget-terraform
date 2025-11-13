module "foundational_security" {
  source     = "../../modules/security"
  account_id = var.account_id
  aws_region = var.aws_region
}

module "foundational_budget" {
  source              = "../../modules/budget"
  account_id          = var.account_id
  notification_emails = var.notification_emails
}