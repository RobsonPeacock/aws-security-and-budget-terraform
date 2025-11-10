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
      identifiers = ["arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = ["repo:RobsonPeacock/aws-security-and-budget-terraform:ref:refs/heads/main"]
    }
  }
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
    ]
    resources = [
      aws_s3_bucket.tf_state_bucket.arn, 
      "${aws_s3_bucket.tf_state_bucket.arn}/*"
    ]
  }

  statement {
    sid    = "AllowDynamoDBLocking"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]
    resources = [
      aws_dynamodb_table.tf_state_locking_table.arn
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