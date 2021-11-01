variable "function_name" {
  type        = string
  description = "Lambda function name"
}

variable "bundle_file_name" {
  type        = string
  description = "Full path to the .js bundle of the lambda function main file"
}


variable "lambda_role_arn" {
  type        = string
  description = "ARN of the lambda execution role for the function"
}
