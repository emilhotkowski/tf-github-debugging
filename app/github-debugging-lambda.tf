resource "aws_lambda_function" "github-debugging-lambda" {
  function_name = "${local.resource_prefix}-github-debugging-lambda"
  
  filename = var.app_zip_location
  source_code_hash = filebase64sha256(var.app_zip_location)
  
  handler = "index.handler"
  runtime = "nodejs12.x"
  
  role = aws_iam_role.default_lambda_role.arn
  
  memory_size = 512
  timeout = 60

  tags = merge(local.common-tags, {})
}

#IAM ROLE
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type = "Service"
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "default_lambda_role" {
  name = "${local.resource_prefix}-default-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = merge(local.common-tags, {})
}

#API Gateway
resource "aws_api_gateway_rest_api" "github-debugging-lambda-api" {
  name = "${local.resource_prefix}-github-debugging-lambda-api"
  description = "prismic-lambda-api for ${local.resource_prefix}"

  tags = merge(local.common-tags, {})
}

resource "aws_lambda_permission" "github-debugging-lambda-api-gw" {
  function_name = aws_lambda_function.github-debugging-lambda.arn
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.github-debugging-lambda-api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_resource" "github-debugging-lambda-api-proxy" {
  rest_api_id = aws_api_gateway_rest_api.github-debugging-lambda-api.id
  parent_id   = aws_api_gateway_rest_api.github-debugging-lambda-api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "github-debugging-lambda-api-resource" {
  rest_api_id   = aws_api_gateway_rest_api.github-debugging-lambda-api.id
  resource_id   = aws_api_gateway_resource.github-debugging-lambda-api-proxy.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "github-debugging-lambda-api_integration" {
  rest_api_id = aws_api_gateway_rest_api.github-debugging-lambda-api.id
  resource_id = aws_api_gateway_method.github-debugging-lambda-api-resource.resource_id
  http_method = aws_api_gateway_method.github-debugging-lambda-api-resource.http_method
  type        = "AWS_PROXY"
  uri         = aws_lambda_function.github-debugging-lambda.invoke_arn

  # AWS lambdas can only be invoked with the POST method
  integration_http_method = "POST"
}

# Deployment
resource "aws_api_gateway_deployment" "github-debugging-lambda-api-deployment" {
  rest_api_id = aws_api_gateway_rest_api.github-debugging-lambda-api.id
  stage_name  = local.resource_prefix

  triggers = {
    redeployment = sha1(join(",", list(
    jsonencode(aws_api_gateway_integration.github-debugging-lambda-api_integration),
    )))
  }

  depends_on = [
    aws_api_gateway_integration.github-debugging-lambda-api_integration,
    aws_api_gateway_method.github-debugging-lambda-api-resource,
  ]

  lifecycle {
    create_before_destroy = true
  }
}