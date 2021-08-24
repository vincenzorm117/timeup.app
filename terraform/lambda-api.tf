################################################
# Lambda function - Invalidates cloudfront


data "archive_file" "api" {
  type        = "zip"
  source_dir  = "../lambdas/starter"
  output_path = "../lambdas/starter.zip"
}


resource "aws_lambda_function" "api" {
  function_name = "TimeUpApi"
  role          = aws_iam_role.api.arn
  handler       = "index.handler"

  filename         = data.archive_file.api.output_path
  source_code_hash = data.archive_file.api.output_base64sha256

  runtime = "nodejs14.x"
  publish = true

  environment {
    variables = {
      OMDB_API_KEY = var.omdb_api_key
      OMDB_API_DOMAIN_NAME = var.omdb_api_domain_name
    }
  }  
}


resource "aws_iam_role" "api" {
  name               = "TimeUpLambdaRole"
  assume_role_policy = data.aws_iam_policy_document.api-role.json
}

data "aws_iam_policy_document" "api-role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    effect = "Allow"
  }
}


resource "aws_iam_role_policy_attachment" "api" {
  role       = aws_iam_role.api.name
  policy_arn = aws_iam_policy.api.arn
}


resource "aws_iam_policy" "api" {
  name        = "TimeUpLambdaPermissions"
  description = ""

  policy = data.aws_iam_policy_document.api.json
}


data "aws_iam_policy_document" "api" {

  statement {
    sid = "Logging"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

}



################################################
# API Gateway Lambda function access


resource "aws_lambda_permission" "api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
