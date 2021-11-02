locals {
  callback_urls         = concat(["${local.url}${var.cognito_path_parse_auth}"], formatlist("%s${var.cognito_path_parse_auth}", var.cognito_additional_redirects))
  logout_urls           = concat(["${local.url}${var.cognito_path_logout}"], formatlist("%s${var.cognito_path_logout}", var.cognito_additional_redirects))

}

data "aws_region" "current" {}

resource "random_pet" "this" {
  length = 2
}

module "lambda_function" {
  for_each = toset(
    ["check-auth", "http-headers", "parse-auth", "refresh-auth", "rewrite-trailing-slash", "sign-out"]
  )

  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 2.0"

  function_name = "${var.name}-${each.value}"
  source_path   = "${path.module}/external/cloudfront-authorization-at-edge/${each.value}.js"  
  handler       = "main.handler"
  runtime       = "nodejs12.x"

  publish        = true
  lambda_at_edge = true

  providers = {
    aws = aws.us-east-1
  }
}



data "aws_route53_zone" "this" {
  name = var.domain
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
  version = "2.0.0" # @todo: revert to "~> 2.0" once 2.1.0 is fixed properly

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
    version = "0.14.2"

    user_pool_name         = "${var.name}-userpool"
    domain                 = "${var.cognito_domain_prefix}.${var.domain}"
    domain_certificate_arn = module.acm.acm_certificate_arn

    clients = [
        {
            name                                 = "${var.name}-client"
            supported_identity_providers         = ["COGNITO"]

            generate_secret                      = true
            allowed_oauth_flows_user_pool_client = true
            allowed_oauth_flows                  = ["code"]
            allowed_oauth_scopes                 = ["openid"]
            callback_urls                        = local.callback_urls
            logout_urls                          = local.logout_urls
        },
    ]
}
