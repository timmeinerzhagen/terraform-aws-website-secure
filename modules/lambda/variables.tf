variable "name" {
  description = "A unique string to use for this module to make sure resources do not clash with others"
  type        = string
}

variable "function" {
  description = "A unique string to use for this module to make sure resources do not clash with others"
  type        = string
}

variable "configuration" {
  description = <<EOF
{
    userPoolArn             = null
    clientId                = null
    clientSecret            = null
    oauthScopes             = ["openid"],
    cognitoAuthDomain       = null
    redirectPathSignIn      = "/parseauth",
    redirectPathSignOut     = "/",
    redirectPathAuthRefresh = "/refreshauth",
    cookieSettings = {
        idToken      = null
        accessToken  = null
        refreshToken = null
        nonce        = null
    }
    mode = "spaMode",
    httpHeaders = {
        Content-Security-Policy   = "default-src 'none'; img-src 'self'; script-src 'self' https://code.jquery.com https://stackpath.bootstrapcdn.com; style-src 'self' 'unsafe-inline' https://stackpath.bootstrapcdn.com; object-src 'none'; connect-src 'self' https://*.amazonaws.com https://*.amazoncognito.com"
        Strict-Transport-Security = "max-age=31536000; includeSubdomains; preload"
        Referrer-Policy           = "same-origin"
        X-XSS-Protection          = "1; mode=block"
        X-Frame-Options           = "DENY"
        X-Content-Type-Options    = "nosniff"
    }
    logLevel            = "none",
    nonceSigningSecret  = null
    cookieCompatibility = "amplify",
    additionalCookies   = {},
    requiredGroup       = ""
}
EOF
  
  type = object({
    userPoolArn             = string,
    clientId                = string,
    clientSecret            = string,
    oauthScopes             = list(string),
    cognitoAuthDomain       = string,
    redirectPathSignIn      = string,
    redirectPathSignOut     = string
    redirectPathAuthRefresh = string,
    cookieSettings = object({
      idToken      = any,
      accessToken  = any,
      refreshToken = any,
      nonce        = any
    }),
    mode = string,
    httpHeaders = object({
      Content-Security-Policy   = string,
      Strict-Transport-Security = string,
      Referrer-Policy           = string,
      X-XSS-Protection          = string,
      X-Frame-Options           = string,
      X-Content-Type-Options    = string
    }),
    logLevel            = string,
    nonceSigningSecret  = string,
    cookieCompatibility = string,
    additionalCookies   = any,
    requiredGroup       = string
  })
}

