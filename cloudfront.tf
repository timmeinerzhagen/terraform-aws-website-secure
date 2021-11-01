locals {
  s3_origin_id      = "${var.name}-S3-website"
  dummy_origin_id   = "${var.name}-dummy-origin"
}

resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "Created for ${var.name}"
}

resource "aws_cloudfront_distribution" "s3_distribution" {

  // S3 main origin
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  // Dummy origin for requests which are handled by lambda@edge
  origin {
    domain_name = "example.com"
    origin_id   = local.dummy_origin_id
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  // Main behaviour
  default_cache_behavior {
    compress = true
    allowed_methods = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"] 
    cached_methods = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.cloudfront_cache_duration
    default_ttl            = var.cloudfront_cache_duration
    max_ttl                = var.cloudfront_cache_duration
    smooth_streaming       = false

    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = module.lambda_edge_function["check-auth"].qualified_arn
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = module.lambda_edge_function["http-headers"].qualified_arn
      include_body = false
    }

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = module.lambda_edge_function["rewrite-trailing-slash"].qualified_arn
      include_body = false
    }
  }

  // Cache behaviour for parse-auth
  ordered_cache_behavior {
    compress = true
    allowed_methods = ["HEAD", "GET", "OPTIONS"]
    cached_methods = ["HEAD", "GET"]
    path_pattern           = var.cognito_path_parse_auth
    target_origin_id       = local.dummy_origin_id
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = module.lambda_edge_function["parse-auth"].qualified_arn
    }
  }

  // Cache behaviour for refresh-auth
  ordered_cache_behavior {
    compress = true
    allowed_methods = ["HEAD", "GET", "OPTIONS"]
    cached_methods = ["HEAD", "GET"]
    path_pattern           = var.cognito_path_refresh_auth
    target_origin_id       = local.dummy_origin_id
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = module.lambda_edge_function["refresh-auth"].qualified_arn
    }
  }

  // Cache behaviour for logout-path
  ordered_cache_behavior {
    compress = true
    allowed_methods = ["HEAD", "GET", "OPTIONS"]
    cached_methods = ["HEAD", "GET"]
    path_pattern           = var.cognito_path_logout
    target_origin_id       = local.dummy_origin_id
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = module.lambda_edge_function["sign-out"].qualified_arn
    }
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  aliases = [var.domain]

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method  = "sni-only"
  }

  # Custom error response to make SPA work, always return index.html for all routes
  dynamic "custom_error_response" {
    for_each = var.is_spa ? [
    0] : []
    content {
      error_code            = 404
      error_caching_min_ttl = 0
      response_page_path    = "/index.html"
      response_code         = 200
    }
  }

}