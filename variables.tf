variable "name" {
  description = "A unique string to use for this module to make sure resources do not clash with others"
  type        = string
}

variable "domain" {
  description = "The primary domain name to use for the website"
  type        = string
}

variable "domain_aliases" {
  description = "A set of any alternative domain names. Typically this would just contain the same as custom_domain but prefixed by www."
  type        = set(string)
  default     = []
}

variable "route53_zone_name" {
  description = "The name of the hosted zone in Route53 where the SSL certificates will be created"
  type        = string
}

variable "is_spa" {
  description = "If your website is a single page application (SPA), this sets up the cloudfront redirects such that whenever an item is not found, the file `index.html` is returned instead."
  default     = false
}

variable "csp" {
  description = "List of default domains to include in the Content Security Policy. Typically you would list the URL of your API here if your pages access that. Always includes `'self'`."
  type = object({
    allow_default  = list(string),
    allow_script   = list(string),
    allow_style    = list(string),
    allow_img      = list(string),
    allow_font     = list(string),
    allow_frame    = list(string),
    allow_manifest = list(string),
    allow_connect  = list(string)
  })
  default = {
    allow_default  = [],
    allow_script   = [],
    allow_style    = [],
    allow_img      = [],
    allow_font     = ["https://fonts.gstatic.com"],
    allow_frame    = [],
    allow_manifest = [],
    allow_connect  = []
  }
}
variable "cognito_path_refresh_auth" {
  description = "Path relative to `custom_domain` to redirect to when a token refresh is required"
  default     = "/refreshauth"
}

variable "cognito_path_logout" {
  description = "Path relative to custom_domain to redirect to after logging out"
  default     = "/"
}

variable "cognito_path_parse_auth" {
  description = "Path relative to custom_domain to redirect to upon successful authentication"
  default     = "/parseauth"
}

variable "cognito_additional_redirects" {
  description = "Additional URLs to allow cognito redirects to"
  type        = list(string)
  default     = []
}

variable "cognito_refresh_token_validity" {
  description = "Time until the refresh token expires and the user will be required to log in again"
  default     = 3650
}

variable "cognito_domain_prefix" {
  description = "The first part of the hosted UI login domain, as in https://[COGNITO_DOMAIN_PREFIX].[CUSTOM_DOMAIN]/"
  type        = string
  default     = "login"
}

variable "content_html_rewrite" {
  description = "Boolean, default false. If true, any URL where the final part does not contain a `.` will reference the S3 object with `html` appended. For example `https://example.com/home` would retrieve the file `home.html` from the website S3 bucket."
  default     = false
  type        = bool
}
