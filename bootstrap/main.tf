resource "aws_s3_bucket" "tf_state_bucket" {
  bucket = "robson-aws-security-budget-tfstate-12345"

  tags = {
    Name        = "TF state bucket"
    Environment = "production"
  }
}

resource "aws_kms_key" "tf_state_bucket_key" {
  description             = "This key is used to encrypt objects stored in the tf state bucket"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_bucket_enc_config" {
  bucket = aws_s3_bucket.tf_state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.tf_state_bucket_key.id
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "tf_state_bucket_versioning" {
  bucket = aws_s3_bucket.tf_state_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "tf_state_locking_table" {
  name         = "tf-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  deletion_protection_enabled = true

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "tf-state-locking"
    Environment = "production"
  }
}

data "aws_iam_policy_document" "tf_state_bucket_policy" {
  statement {
    sid    = "ForceEncryption"
    effect = "Deny"
    principals {
      type = "AWS"
      # Deny access to everyone if they aren't using encryption
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.tf_state_bucket.arn}/*",
    ]

    condition {
      # This condition checks if the object is being uploaded without AES256 encryption
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256"]
    }
  }

  statement {
    sid       = "ForceSecureTransport"
    effect    = "Deny"
    principals {
      type        = "AWS"
      # Deny access to everyone if they aren't using HTTPS
      identifiers = ["*"]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.tf_state_bucket.arn,
      "${aws_s3_bucket.tf_state_bucket.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "tf_state_bucket_policy" {
  bucket = aws_s3_bucket.tf_state_bucket.id
  policy = data.aws_iam_policy_document.tf_state_bucket_policy.json
}