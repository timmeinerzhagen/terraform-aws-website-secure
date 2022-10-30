data "aws_canonical_user_id" "current" {}

module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "2.9.3"

  aliases = [var.domain]

  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  create_origin_access_identity = true
  origin_access_identities = {
    website = "Access website content"
  }

  origin = {
    s3 = {
      domain_name = module.website-bucket.s3_bucket_bucket_regional_domain_name
      s3_origin_config = {
        origin_access_identity = "website"
      }
    }

    dummy = {
      domain_name = "example.com"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3"
    viewer_protocol_policy = "allow-all"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true

    lambda_function_association = {
      viewer-request = {
        lambda_arn = module.lambda_function["check-auth"].lambda_function_qualified_arn
      }

      origin-response = {
        lambda_arn   = module.lambda_function["http-headers"].lambda_function_qualified_arn
        include_body = false
      }

      origin-request = {
        lambda_arn   = module.lambda_function["rewrite-trailing-slash"].lambda_function_qualified_arn
        include_body = false
      }
    }
  }

  ordered_cache_behavior = [
    {
      path_pattern           = var.cognito_path_parse_auth
      target_origin_id       = "dummy"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true

      lambda_function_association = {
        viewer-request = {
          lambda_arn = module.lambda_function["parse-auth"].lambda_function_qualified_arn
        }
      }
    },
    {
      path_pattern           = var.cognito_path_refresh_auth
      target_origin_id       = "dummy"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true

      lambda_function_association = {
        viewer-request = {
          lambda_arn = module.lambda_function["refresh-auth"].lambda_function_qualified_arn
        }
      }
    },
    {
      path_pattern           = var.cognito_path_logout
      target_origin_id       = "dummy"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true

      lambda_function_association = {
        viewer-request = {
          lambda_arn = module.lambda_function["sign-out"].lambda_function_qualified_arn
        }
      }
    },

  ]

  viewer_certificate = {
    acm_certificate_arn = module.acm.acm_certificate_arn
    ssl_support_method  = "sni-only"
  }

  logging_config = {
    bucket = module.log_bucket.s3_bucket_bucket_domain_name
  }

}

module "website-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.4.1"

  bucket                  = "s3-${random_pet.this.id}"
  force_destroy           = true
  restrict_public_buckets = true
  ignore_public_acls      = true
  block_public_acls       = true
  block_public_policy     = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning = {
    enabled = true
  }

  logging = {
    target_bucket = module.log_bucket.s3_bucket_id
    target_prefix = "log/"
  }
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.website-bucket.s3_bucket_arn}/*"]

    principals {
      type        = "AWS"
      identifiers = module.cloudfront.cloudfront_origin_access_identity_iam_arns
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = module.website-bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.s3_policy.json
}

module "log_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.4.1"

  bucket = "logs-${random_pet.this.id}"
  acl    = null
  grant = [{
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
    id          = data.aws_canonical_user_id.current.id
    }, {
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
    id          = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
    # Ref. https://github.com/terraform-providers/terraform-provider-aws/issues/12512
    # Ref. https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html
  }]

  force_destroy           = true
  restrict_public_buckets = true
  ignore_public_acls      = true
  block_public_acls       = true
  block_public_policy     = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning = {
    enabled = true
  }
}
