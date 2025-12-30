resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]
}

data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:RobsonPeacock/aws-security-and-budget-terraform:ref:refs/heads/main"]
    }
  }
}

data "aws_budgets_budget" "monthly" {
  name = "Monthly-Account-Limit"
}

resource "aws_iam_role" "github_actions_tf_role" {
  name               = "github-actions-tf-role"
  description        = "Role for GitHub Actions to deploy Terraform infrastructure."
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
}

data "aws_iam_policy_document" "tf_deploy_permissions" {
  statement {
    sid    = "AllowS3StateAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetBucketPolicy",
      "s3:GetBucketAcl",
      "s3:GetBucketCORS",
      "s3:GetBucketWebsite",
      "s3:GetBucketVersioning",
      "s3:GetAccelerateConfiguration",
      "s3:GetBucketRequestPayment",
      "s3:GetBucketLogging",
      "s3:GetBucketLocation",
      "s3:GetEncryptionConfiguration",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketTagging",
      "s3:GetLifecycleConfiguration",
      "s3:GetReplicationConfiguration",
      "s3:GetBucketObjectLockConfiguration"
    ]
    resources = [
      aws_s3_bucket.tf_state_bucket.arn,
      "${aws_s3_bucket.tf_state_bucket.arn}/*",
      "arn:aws:s3:::rp-cloudtrail-log-bucket-*",
      "arn:aws:s3:::rp-cloudtrail-log-bucket-*/*"
    ]
  }

  statement {
    sid    = "AllowDynamoDBLocking"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeContinuousBackups",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:ListTagsOfResource"
    ]
    resources = [
      aws_dynamodb_table.tf_state_locking_table.arn
    ]
  }

  statement {
    sid    = "AllowReadOIDCProvider"
    effect = "Allow"
    actions = [
      "iam:GetOpenIDConnectProvider"
    ]
    resources = [
      aws_iam_openid_connect_provider.github.arn
    ]
  }

  statement {
    sid    = "AllowReadCIRole"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
    ]
    resources = [
      aws_iam_role.github_actions_tf_role.arn
    ]
  }

  statement {
    sid    = "AllowGetDeployPolicy"
    effect = "Allow"
    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions"
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:policy/Terraform-Deploy-Policy"
    ]
  }

  statement {
    sid    = "AllowGetBudgets"
    effect = "Allow"
    actions = [
      "budgets:ViewBudget",
      "budgets:ListTagsForResource"
    ]
    resources = [
      data.aws_budgets_budget.monthly.arn
    ]
  }

  statement {
    sid    = "AllowCloudTrailDiscovery"
    effect = "Allow"
    actions = [
      "cloudtrail:DescribeTrails"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowManageSecurityTrail"
    effect = "Allow"
    actions = [
      "cloudtrail:GetTrailStatus",
      "cloudtrail:ListTags"
    ]
    resources = [
      "arn:aws:cloudtrail:${var.aws_region}:${local.account_id}:trail/rp-account-security-trail"
    ]
  }
}

resource "aws_iam_policy" "tf_deploy_policy" {
  name   = "Terraform-Deploy-Policy"
  policy = data.aws_iam_policy_document.tf_deploy_permissions.json
}

resource "aws_iam_role_policy_attachment" "attach_tf_deploy_policy" {
  role       = aws_iam_role.github_actions_tf_role.name
  policy_arn = aws_iam_policy.tf_deploy_policy.arn
}