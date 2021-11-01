terraform {
  required_version = ">= 1.0.2"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 3.50.0, < 4.0.0"
    }
    aws-us-east-1 = {
      source = "hashicorp/aws"
      version = ">= 3.50.0, < 4.0.0"
    }
    archive = {
      source = "hashicorp/archive"
      version = ">= 2.2.0, < 3.0.0"
    }
  }
}
