module "foundational_security" {
  source = "../../modules/security"
  account_id = var.account_id
  aws_region = var.aws_region
}