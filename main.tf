provider "aws" {
  profile = var.profile
  region = var.region

  assume_role {
    role_arn = var.assumeRole ? "arn:aws:iam::${var.accountID}:role/${var.assumableRole}" : null
  }
}

resource "aws_s3_bucket" "vss" {
  bucket              = var.name
  object_lock_enabled = var.object_lock_enabled

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "vss" {
  bucket = "${aws_s3_bucket.vss.id}"

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets

  depends_on = [aws_s3_bucket.vss]
}

data "template_file" "vss" {
  template = file("${var.policy_path}/${var.name}.json")
  vars = {
    arn = "${aws_s3_bucket.vss.arn}"
  }
}

resource "aws_s3_bucket_policy" "vss" {
  bucket = aws_s3_bucket.vss.id
  policy = data.template_file.vss.rendered

  depends_on = [aws_s3_bucket.vss]
}

resource "aws_s3_bucket_versioning" "vss" {
  count = var.versioning_enabled ? 1 : 0
  bucket = aws_s3_bucket.vss.id
  versioning_configuration {
    status = try(rule.value.enabled ? "Enabled" : "Suspended", "Suspended")
  }

  depends_on = [aws_s3_bucket.vss]
}

resource "aws_s3_bucket_logging" "vss" {
  count = var.logging_bucket != "" ? 1 : 0
  bucket = aws_s3_bucket.vss.id

  target_bucket = var.logging_bucket
  target_prefix = "${var.logging_prefix}/${var.name}/"

  depends_on = [aws_s3_bucket.vss]
}

resource "aws_s3_bucket_lifecycle_configuration" "vss" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.vss.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = try(rule.value.name, null)
      status = try(rule.value.enabled ? "Enabled" : "Disabled", "Disabled")

      dynamic "abort_incomplete_multipart_upload" {
        for_each = try([rule.value.abort_incomplete_multipart_in_days], [])

        content {
          days_after_initiation = rule.value.abort_incomplete_multipart_in_days
        }
      }

      dynamic "filter" {
        for_each = rule.value.filters
        content {
          and {
            object_size_greater_than = try(filter.value.object_size_greater_than, null)
            object_size_less_than    = try(filter.value.object_size_less_than, null)
            prefix                   = try(filter.value.prefix, null)
            dynamic "tags" {
              for_each = filter.value.tags
              content {
                "${tags.value.key}" = "${tags.value.value}"
              }
            }
          }
        }
      }

      expiration {
        date = try(rule.value.expiration_date != "" ? rule.value.expiration_date : null, null)
        days = try(rule.value.expiration_date == "" && rule.value.expiration_days > 0 ? rule.value.expiration_days : null, null)
      }

      transition {
        date = try(rule.value.transition_date != "" ? rule.value.transition_date : null, null)
        days = try(rule.value.transition_date == "" && rule.value.transition_days > 0 ? rule.value.transition_days : null, null)
      }
    }
  }

  depends_on = [aws_s3_bucket.vss]
}

resource "aws_s3_bucket_website_configuration" "vss" {
  count = var.website_enabled && var.website_index_page != "" && var.website_error_page != "" ? 1 : 0
  bucket = aws_s3_bucket.vss.id

  index_document {
    suffix = var.website_index_page
  }

  error_document {
    key = var.website_error_page
  }

  depends_on = [aws_s3_bucket.vss]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vss" {
  count = var.encryption_enabled ? 1 : 0
  bucket = aws_s3_bucket.vss.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_algorithm
      kms_master_key_id = try(var.encryption_kms_key, null)
    }
  }

  depends_on = [aws_s3_bucket.vss]
}