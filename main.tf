provider "aws" {
  profile = var.profile
  region = var.region

  assume_role {
    role_arn = var.assumeRole ? "arn:aws:iam::${var.accountID}:role/${var.assumableRole}" : null
  }
}

locals {
  lifecycle_rules      = try(jsondecode(var.lifecycle_rules), var.lifecycle_rules)
  cors_rules           = try(jsondecode(var.cors_rules), var.cors_rules)
}

resource "aws_s3_bucket" "vss" {
  bucket              = var.name
  object_lock_enabled = var.object_lock_enabled
}

resource "aws_s3_bucket_object_lock_configuration" "vss" {
  count = var.object_lock_enabled && length(var.object_lock_config) > 0 ? 1 : 0

  bucket = aws_s3_bucket.vss.id

  dynamic "rule" {
    for_each = try([var.object_lock_config],[])
    content {
      default_retention {
        mode = try(rule.value.mode, "COMPLIANCE")
        days = try(rule.value.days, null)
      }
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "vss" {
  count = length(local.cors_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.vss.id

  dynamic "cors_rule" {
    for_each = try([var.cors_rules],[])

    content {
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      allowed_headers = try(cors_rule.value.allowed_headers, null)
      expose_headers  = try(cors_rule.value.expose_headers, null)
    }
  }

  depends_on = [aws_s3_bucket.vss]
}

resource "aws_s3_bucket_notification" "vss" {
  count = var.notification_enabled ? 1 : 0
  bucket = aws_s3_bucket.vss.id

  dynamic "queue" {
    for_each = try([var.notification_sqs],[])

    content {
      queue_arn = queue.value.queue_arn
      events = queue.value.events
      filter_suffix = queue.value.filter_suffix
    }
  }

  dynamic "lambda_function" {
    for_each = try([var.notification_lambda],[])

    content {
      lambda_function_arn = lambda_function.value.lambda_function_arn
      events = lambda_function.value.events
      filter_suffix = lambda_function.value.filter_suffix
    }
  }

  depends_on = [aws_s3_bucket.vss]
}

resource "aws_s3_bucket_public_access_block" "vss" {
  bucket = aws_s3_bucket.vss.id

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
    status = var.versioning_enabled ? "Enabled" : "Suspended"
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

resource "aws_s3_bucket_lifecycle_configuration" "vss" {
  count = length(local.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.vss.id

  dynamic "rule" {
    for_each = local.lifecycle_rules
    content {
      id     = try(rule.value.name, null)
      status = try(rule.value.enabled ? "Enabled" : "Disabled", "Enabled")

      dynamic "abort_incomplete_multipart_upload" {
        for_each = try([rule.value.abort_incomplete_multipart_in_days], [])

        content {
          days_after_initiation = rule.value.abort_incomplete_multipart_in_days
        }
      }

      dynamic "filter" {
        for_each = try([rule.value.filter],[])
        content {
          and {
            object_size_greater_than = try(filter.value.object_size_greater_than, null)
            object_size_less_than    = try(filter.value.object_size_less_than, null)
            prefix                   = try(filter.value.prefix, null)
            tags                     = try(filter.value.tags, null)
          }
        }
      }

      dynamic "expiration" {
        for_each = try(flatten([rule.value.expiration]), [])
        content {
          date = try(expiration.value.date, null)
          days = try(expiration.value.days, null)
        }
      }

      dynamic "transition" {
        for_each = try(flatten([rule.value.transition]), [])
        content {
          date = try(transition.value.date, null)
          days = try(transition.value.days, null)
          storage_class = transition.value.storage_class
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.vss]
}