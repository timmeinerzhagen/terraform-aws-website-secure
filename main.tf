locals {
  callback_urls         = concat(["${local.url}${var.cognito_path_parse_auth}"], formatlist("%s${var.cognito_path_parse_auth}", var.cognito_additional_redirects))
  logout_urls           = concat(["${local.url}${var.cognito_path_logout}"], formatlist("%s${var.cognito_path_logout}", var.cognito_additional_redirects))

}

data "aws_region" "current" {}


/* Cognito */
resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.name}-user-pool"
  admin_create_user_config {
    allow_admin_create_user_only = true
  }
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                                 = "${var.name}-client"

  supported_identity_providers         = ["COGNITO"]
  user_pool_id                         = aws_cognito_user_pool.user_pool.id
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid"]
  prevent_user_existence_errors        = "ENABLED"

  callback_urls                        = local.callback_urls
  logout_urls                          = local.logout_urls
  refresh_token_validity               = var.cognito_refresh_token_validity
}

resource "aws_cognito_user_pool_domain" "login" {
  domain          = var.cognito_domain_prefix
  certificate_arn = aws_acm_certificate.ssl_certificate.arn
  user_pool_id    = aws_cognito_user_pool.user_pool.id
}
