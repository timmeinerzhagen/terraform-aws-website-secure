locals {
  cspString = join("; ", [for k, v in {
    default : concat(["self"], var.csp.allow_default),
    script : var.csp.allow_script,
    style : var.csp.allow_style,
    img : var.csp.allow_img,
    font : var.csp.allow_font,
    frame : var.csp.allow_frame,
    manifest : concat(["self"], var.csp.allow_manifest),
    connect : var.csp.allow_connect,
  } : "${k}-src ${join(" ", concat(["'self'"], v))}"])
  headers = {
    Cache-Control : "public, max-age=${var.cloudfront_cache_duration}"
    Content-Security-Policy   = local.cspString
    Strict-Transport-Security = "max-age=63072000; includeSubdomains; preload"
    X-Content-Type-Options    = "nosniff"
    X-Frame-Options           = "DENY"
    X-XSS-Protection          = "1; mode=block"
    Referrer-Policy           = "strict-origin"
  }
  cookie_settings = <<EOF
{
  "idToken": null,
  "accessToken": null,
  "refreshToken": null,
  "nonce": null
}
EOF
}

module "lambda_edge_function" {
  for_each = setunion(toset(["check-auth", "http-headers", "parse-auth", "refresh-auth", "rewrite-trailing-slash", "sign-out"]))

  source = "./modules/lambda_edge_function"

  function_name    = "${var.name}-${each.value}"
  bundle_file_name = "${path.module}/external/cloudfront-authorization-at-edge/${each.value}.js"
  lambda_role_arn  = aws_iam_role.iam_for_lambda_edge.arn

  providers = {
    aws = aws.us-east-1
  }
}

resource "random_password" "nonce_secret" {
  length           = 16
  special          = true
  override_special = "-._~"
}

resource "aws_iam_role" "iam_for_lambda_edge" {
  name               = "${var.name}-iam_for_lambda_edge"
  provider           = aws.us-east-1
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "edgelambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


/* Policy attached to lambda execution role to allow logging */
resource "aws_iam_role_policy" "lambda_log_policy" {
  name = "${var.name}-lambda_log_policy"
  role = aws_iam_role.iam_for_lambda_edge.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}