resource "aws_securityhub_account" "security_hub" {
  auto_enable_controls = false
}

resource "aws_cloudtrail" "account_security_trail" {
  name = "rp-account-security-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_log_bucket.id
}

resource "aws_s3_bucket" "cloudtrail_log_bucket" {
  bucket = "rp-cloudtrail-log-bucket-12345"

  tags = {
    Name        = "Cloudtrail log bucket"
    Environment = "production"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_bucket_encryption" {
  bucket = aws_s3_bucket.cloudtrail_log_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_bucket_block" {
  bucket = aws_s3_bucket.cloudtrail_log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "cloudtrail_log_bucket_policy_doc" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_log_bucket.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudtrail.account_security_trail.arn]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail_log_bucket.arn}/AWSLogs/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudtrail.account_security_trail.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_log_bucket_policy_doc" {
  bucket = aws_s3_bucket.cloudtrail_log_bucket.id
  policy = data.aws_iam_policy_document.cloudtrail_log_bucket_policy_doc.json
}

resource "aws_s3_bucket" "config_bucket" {
  bucket = "rp-aws-config-bucket"

  tags = {
    Name = "AWS Config bucket"
    Environment = "production"
  }
}

data "aws_iam_policy_document" "config_bucket_policy_doc" {
  statement {
    sid    = "AWSConfigBucketPermissionsCheck"
    effect = "Allow"
    actions = ["s3:GetBucketAcl"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    resources = [
      aws_s3_bucket.config_bucket.arn,
    ]
  }

  statement {
    sid    = "AWSConfigBucketDelivery"
    effect = "Allow"
    actions = ["s3:PutObject"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    resources = [
      "${aws_s3_bucket.config_bucket.arn}/*",
    ]

    condition { 
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.config_bucket.id
  policy = data.aws_iam_policy_document.config_bucket_policy_doc.json
}

data "aws_iam_policy_document" "config_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "config_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_role" "config_role" {
  name               = "aws-config-service-role"
  assume_role_policy = data.aws_iam_policy_document.config_assume_role.json
}

resource "aws_iam_role_policy_attachment" "config_bucket_attachment" {
  role = aws_iam_role.config_role.name
  policy_arn = data.aws_iam_policy.config_role_policy.arn
}