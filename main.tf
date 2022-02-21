locals {
  callback_urls = concat(["https://${var.domain}${var.cognito_path_parse_auth}"], formatlist("%s${var.cognito_path_parse_auth}", var.cognito_additional_redirects))
  logout_urls   = concat(["https://${var.domain}${var.cognito_path_logout}"], formatlist("%s${var.cognito_path_logout}", var.cognito_additional_redirects))
  functions = toset(
    ["check-auth", "http-headers", "parse-auth", "refresh-auth", "rewrite-trailing-slash", "sign-out"]
  )
}

resource "random_pet" "this" {
  length = 2
}
data "aws_route53_zone" "this" {
  name = var.domain
}

module "lambda_function" {
  for_each = local.functions

  source = "./modules/lambda"

  name     = var.name
  function = each.value
  configuration = jsondecode(<<EOF
{
  "userPoolArn": "${module.cognito-user-pool.arn}",
  "clientId": "${module.cognito-user-pool.client_ids[0]}",
  "clientSecret": "${module.cognito-user-pool.client_secrets[0]}",
  "oauthScopes": ["openid"],
  "cognitoAuthDomain": "${var.cognito_domain_prefix}.${var.domain}",
  "redirectPathSignIn": "${var.cognito_path_parse_auth}",
  "redirectPathSignOut": "${var.cognito_path_logout}",
  "redirectPathAuthRefresh": "${var.cognito_path_refresh_auth}",
  "cookieSettings": { "idToken": null, "accessToken": null, "refreshToken": null, "nonce": null },
  "mode": "spaMode",
  "httpHeaders": {
      "Content-Security-Policy": "default-src 'none'; img-src 'self'; script-src 'self' https://code.jquery.com https://stackpath.bootstrapcdn.com; style-src 'self' 'unsafe-inline' https://stackpath.bootstrapcdn.com; object-src 'none'; connect-src 'self' https://*.amazonaws.com https://*.amazoncognito.com",
      "Strict-Transport-Security": "max-age=31536000; includeSubdomains; preload",
      "Referrer-Policy": "same-origin",
      "X-XSS-Protection": "1; mode=block",
      "X-Frame-Options": "DENY",
      "X-Content-Type-Options":  "nosniff"
  },
  "logLevel": "none",
  "nonceSigningSecret": "jvfg108gfhjhg!&%j91kt",
  "cookieCompatibility": "amplify",
  "additionalCookies": {},
  "requiredGroup": ""
}
EOF
  )

  providers = {
    aws = aws.us-east-1
  }
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  domain_name               = var.domain
  subject_alternative_names = ["*.${var.domain}"]
  zone_id                   = data.aws_route53_zone.this.id

  providers = {
    aws = aws.us-east-1
  }
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "2.5.0" # @todo: revert to "~> 2.0" once 2.1.0 is fixed properly

  zone_id = data.aws_route53_zone.this.zone_id

  records = [
    {
      name = ""
      type = "A"
      alias = {
        name    = module.cloudfront.cloudfront_distribution_domain_name
        zone_id = module.cloudfront.cloudfront_distribution_hosted_zone_id
      }
    },
  ]
}

module "cognito-user-pool" {
  source  = "lgallard/cognito-user-pool/aws"
  version = "0.15.2"

  user_pool_name         = "${var.name}-userpool"
  domain                 = "${var.cognito_domain_prefix}.${var.domain}"
  domain_certificate_arn = module.acm.acm_certificate_arn

  clients = [
    {
      name                         = "${var.name}-client"
      supported_identity_providers = ["COGNITO"]

      generate_secret                      = true
      allowed_oauth_flows_user_pool_client = true
      allowed_oauth_flows                  = ["code"]
      allowed_oauth_scopes                 = ["openid"]
      callback_urls                        = local.callback_urls
      logout_urls                          = local.logout_urls
    },
  ]
}

resource "aws_route53_record" "cognito-domain" {
  name    = "${var.cognito_domain_prefix}.${var.domain}"
  type    = "A"
  zone_id = data.aws_route53_zone.this.zone_id
  alias {
    evaluate_target_health = false
    name                   = module.cognito-user-pool.domain_cloudfront_distribution_arn
    # This zone_id is fixed
    zone_id = "Z2FDTNDATAQYW2"
  }
}
