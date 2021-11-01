terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.50.0, < 4.0.0"
    }
  }
}

data "archive_file" "lambda_edge_zip" {
  type        = "zip"
  output_path = "${path.root}/.terraform/artifacts/${var.function_name}.zip"

  source {
    content  = file(var.bundle_file_name)
    filename = "main.js"
  }
}

resource "aws_lambda_function" "lambda_edge_function" {
  function_name    = var.function_name

  filename         = data.archive_file.lambda_edge_zip.output_path
  source_code_hash = data.archive_file.lambda_edge_zip.output_base64sha256
  handler          = "main.handler"
  runtime          = "nodejs12.x"
  role             = var.lambda_role_arn
  
  timeout          = 5
  memory_size      = 128
  publish          = true
}
