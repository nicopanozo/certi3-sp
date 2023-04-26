provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "origin" {
  bucket = "example-origin-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  replication_configuration {
    role = aws_iam_role.s3_replication.arn

    rule {
      id      = "example-rule"
      prefix  = ""
      status  = "Enabled"

      destination {
        bucket        = aws_s3_bucket.destination.arn
        replica_kms_key_id = data.aws_kms_key.default.arn
        storage_class = "STANDARD"
      }

      source_selection_criteria {
        sse_kms_encrypted_objects {
          enabled = true
        }
      }
    }
  }
}

resource "aws_s3_bucket" "destination" {
  bucket = "example-destination-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }
}

data "aws_iam_policy_document" "s3_replication" {
  statement {
    actions = [
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectAcl",
      "s3:GetObjectTagging",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging"
    ]

    resources = [
      "${aws_s3_bucket.origin.arn}/*",
      "${aws_s3_bucket.destination.arn}/*"
    ]
  }
}

resource "aws_iam_role" "s3_replication" {
  name = "example-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_replication" {
  name   = "example-s3-replication-policy"
  policy = data.aws_iam_policy_document.s3_replication.json
  role   = aws_iam_role.s3_replication.id
}

data "aws_kms_key" "default" {
  key_id = "alias/aws/s3"
}
