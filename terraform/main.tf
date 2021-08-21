locals {
  api_domain_name = "api.${var.domain}"
}

################################################
# API Gateway

resource "aws_api_gateway_rest_api" "api" {
  name        = "TimeUp"
  description = "TimeUp proxy-lambda API."

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  disable_execute_api_endpoint = false
}

resource "aws_api_gateway_method" "api" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_rest_api.api.root_resource_id
  http_method             = aws_api_gateway_method.api.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api.invoke_arn
}

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "v1"
}


resource "aws_api_gateway_domain_name" "api" {
  regional_certificate_arn = aws_acm_certificate_validation.timeup.certificate_arn
  domain_name     = local.api_domain_name

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_stage" "api" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "v1"
}

resource "aws_api_gateway_base_path_mapping" "api" {
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.api.stage_name
  domain_name = aws_api_gateway_domain_name.api.domain_name
}



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
