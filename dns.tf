data "aws_route53_zone" "hosted_zone" {
  name         = var.route53_zone_name
  private_zone = false
}

resource "aws_route53_record" "website" {
  name    = aws_acm_certificate.ssl_certificate.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.hosted_zone.id

  alias {
    evaluate_target_health = true
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
  }
}

resource "aws_route53_record" "cognito" {
  name    = aws_cognito_user_pool_domain.login.domain
  type    = "A"
  zone_id = data.aws_route53_zone.hosted_zone.zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_cognito_user_pool_domain.login.cloudfront_distribution_arn
    zone_id                = "Z2FDTNDATAQYW2"
  }
}


/* SSL Certificate & Validation */

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.ssl_certificate.arn
  validation_record_fqdns = [for validation in aws_route53_record.record_cert : validation.fqdn]
  provider                = aws.us-east-1
}

resource "aws_acm_certificate" "ssl_certificate" {
  domain_name               = var.domain
  subject_alternative_names = ["*.${var.domain}"]
  validation_method         = "DNS"

  provider = aws.us-east-1
}

resource "aws_route53_record" "record_cert" {
  for_each = {
    for dvo in aws_acm_certificate.ssl_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  type    = each.value.type
  zone_id = data.aws_route53_zone.hosted_zone.id
  records = [each.value.record]
  ttl     = 60

  provider = aws.us-east-1
}

