# terraform-aws-website-secure
Creates a  private website behind a cloudfront distribution, with SSL enabled. Custom Cognito hosted UI is put in front of it.

The website files are hosted in an S3 bucket which is also created by the module.

# Usage
```hcl-terraform
module "website" {
    source = "timmeinerzhagen/website-secure/aws"
    
    name           = "tf-my-project"
    domain         = "example.com"
    custom_domain  = "example.com"
    domain_aliases = ["www.example.com"]
    is_spa         = false
    csp            = {
        allow_default = ["api.mysite.com"]
        allow_style = ["'unsafe-inline'"]
        allow_img = ["data:"]
        allow_font = []
        allow_frame = []
        allow_manifest = []
        allow_connect = []
    }

    cloudfront_cache_duration = 86400

    cognito_path_refresh_auth       = "/refreshauth"
    cognito_path_logout             = "/"
    cognito_path_parse_auth         = "/parseauth"
    cognito_refresh_token_validity  = 3650
    cognito_additional_redirects    = ["http://localhost:3000"]  // Useful for development purposes
    cognito_domain_prefix           = "login"
}

```
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.2 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.2.0, < 3.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.61.0, < 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.64.2 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm"></a> [acm](#module\_acm) | terraform-aws-modules/acm/aws | ~> 3.0 |
| <a name="module_cloudfront"></a> [cloudfront](#module\_cloudfront) | terraform-aws-modules/cloudfront/aws | 2.8.0 |
| <a name="module_cognito-user-pool"></a> [cognito-user-pool](#module\_cognito-user-pool) | lgallard/cognito-user-pool/aws | 0.14.2 |
| <a name="module_lambda_function"></a> [lambda\_function](#module\_lambda\_function) | ./modules/lambda | n/a |
| <a name="module_log_bucket"></a> [log\_bucket](#module\_log\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 2.0 |
| <a name="module_records"></a> [records](#module\_records) | terraform-aws-modules/route53/aws//modules/records | 2.3.0 |
| <a name="module_website-bucket"></a> [website-bucket](#module\_website-bucket) | terraform-aws-modules/s3-bucket/aws | ~> 2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_route53_record.cognito-domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket_policy.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [random_pet.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [aws_canonical_user_id.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/canonical_user_id) | data source |
| [aws_iam_policy_document.s3_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cognito_additional_redirects"></a> [cognito\_additional\_redirects](#input\_cognito\_additional\_redirects) | Additional URLs to allow cognito redirects to | `list(string)` | `[]` | no |
| <a name="input_cognito_domain_prefix"></a> [cognito\_domain\_prefix](#input\_cognito\_domain\_prefix) | The first part of the hosted UI login domain, as in https://[COGNITO_DOMAIN_PREFIX].[CUSTOM_DOMAIN]/ | `string` | `"login"` | no |
| <a name="input_cognito_path_logout"></a> [cognito\_path\_logout](#input\_cognito\_path\_logout) | Path relative to custom\_domain to redirect to after logging out | `string` | `"/"` | no |
| <a name="input_cognito_path_parse_auth"></a> [cognito\_path\_parse\_auth](#input\_cognito\_path\_parse\_auth) | Path relative to custom\_domain to redirect to upon successful authentication | `string` | `"/parseauth"` | no |
| <a name="input_cognito_path_refresh_auth"></a> [cognito\_path\_refresh\_auth](#input\_cognito\_path\_refresh\_auth) | Path relative to `custom_domain` to redirect to when a token refresh is required | `string` | `"/refreshauth"` | no |
| <a name="input_cognito_refresh_token_validity"></a> [cognito\_refresh\_token\_validity](#input\_cognito\_refresh\_token\_validity) | Time until the refresh token expires and the user will be required to log in again | `number` | `3650` | no |
| <a name="input_content_html_rewrite"></a> [content\_html\_rewrite](#input\_content\_html\_rewrite) | Boolean, default false. If true, any URL where the final part does not contain a `.` will reference the S3 object with `html` appended. For example `https://example.com/home` would retrieve the file `home.html` from the website S3 bucket. | `bool` | `false` | no |
| <a name="input_csp"></a> [csp](#input\_csp) | List of default domains to include in the Content Security Policy. Typically you would list the URL of your API here if your pages access that. Always includes `'self'`. | <pre>object({<br>    allow_default  = list(string),<br>    allow_script   = list(string),<br>    allow_style    = list(string),<br>    allow_img      = list(string),<br>    allow_font     = list(string),<br>    allow_frame    = list(string),<br>    allow_manifest = list(string),<br>    allow_connect  = list(string)<br>  })</pre> | <pre>{<br>  "allow_connect": [],<br>  "allow_default": [],<br>  "allow_font": [<br>    "https://fonts.gstatic.com"<br>  ],<br>  "allow_frame": [],<br>  "allow_img": [],<br>  "allow_manifest": [],<br>  "allow_script": [],<br>  "allow_style": []<br>}</pre> | no |
| <a name="input_domain"></a> [domain](#input\_domain) | The primary domain name to use for the website | `string` | n/a | yes |
| <a name="input_domain_aliases"></a> [domain\_aliases](#input\_domain\_aliases) | A set of any alternative domain names. Typically this would just contain the same as custom\_domain but prefixed by www. | `set(string)` | `[]` | no |
| <a name="input_is_spa"></a> [is\_spa](#input\_is\_spa) | If your website is a single page application (SPA), this sets up the cloudfront redirects such that whenever an item is not found, the file `index.html` is returned instead. | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | A unique string to use for this module to make sure resources do not clash with others | `string` | n/a | yes |
| <a name="input_route53_zone_name"></a> [route53\_zone\_name](#input\_route53\_zone\_name) | The name of the hosted zone in Route53 where the SSL certificates will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alternate_urls"></a> [alternate\_urls](#output\_alternate\_urls) | Alternate URLs of the website |
| <a name="output_url"></a> [url](#output\_url) | URL of the main website |
