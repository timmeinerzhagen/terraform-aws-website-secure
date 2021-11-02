provider "aws" {
  region = "eu-west-1"
}
provider "aws" {
  alias = "us-east-1"
  region = "us-east-1"
}

module "test_website" {
  source = "timmeinerzhagen/website-secure/aws"

  name = "tf-website-secure"
  domain = "example.com"
  route53_zone_name = "example.com"

  providers = {
      aws: aws.default
      aws.us-east-1: aws.us-east-1
  }
} 
