// After this user is created by Terraform, generate access credentials for it and pass them
// to CI through configuration.
resource "aws_iam_user" "lambdas-ci" {
  name = "${local.resource_prefix}-lambdas-ci-user"

  tags = merge(local.common-tags, {})
}

data "aws_iam_policy_document" "lambdas-ci" {
  statement {
    sid = "ListAllBuckets"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets"
    ]
    resources = ["arn:aws:s3:::${var.lambdas_s3_state_bucket}"]
  }

  statement {
    sid = "ListWholeTFStateBucket"
    effect = "Allow"
    actions = [
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid = "ListUserPools"
    effect = "Allow"
    actions = [
      "cognito-idp:List*",
      "cognito-idp:Describe*",
      "cognito-idp:GetUserPoolMfaConfig",
    ]
    resources = [
      "*"
    ]
  }

//  statement {
//    sid = "ReadWriteAccessToTerraformState"
//    effect = "Allow"
//    actions = [
//      "s3:ListBucket",
//      "s3:ListBucketMultipartUploads",
//      "s3:AbortMultipartUpload",
//      "s3:GetObject",
//      "s3:GetObjects",
//      "s3:DeleteObject",
//      "s3:DeleteObjects",
//      "s3:PutObject",
//      "s3:PutObjects"
//    ]
//    resources = [
//      "arn:aws:s3:::${var.lambdas_s3_state_bucket}/${var.github_debugging_lambdas_s3_state}",
//    ]
//  }

  # Lambda functions CANNOT use prefix-based wildcard permissions.
  # https://docs.aws.amazon.com/lambda/latest/dg/API_AddPermission.html#SSS-AddPermission-request-FunctionName
  statement {
    sid = "UpdateLambda"
    effect = "Allow"
    actions = [
      "lambda:*"
    ]
    resources = [
      "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${local.resource_prefix}-*",
    ]
  }

  statement {
    sid = "UpdateLambdaEventSourceMappings"
    effect = "Allow"
    actions = [
      "lambda:CreateEventSourceMapping",
      "lambda:UpdateEventSourceMapping",
      "lambda:DeleteEventSourceMapping"
    ]
    resources = ["*"]

    condition {
      test = "StringLike"
      variable = "lambda:FunctionArn"

      values = [
        "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${local.resource_prefix}-*"
      ]
    }
  }

  statement {
    sid = "GetRestApis"
    effect = "Allow"
    actions = [
      "apigateway:Get*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "lambdas-ci" {
  name = "${local.resource_prefix}-lambdas-ci-user-access-policy"
  user = aws_iam_user.lambdas-ci.name

  policy = data.aws_iam_policy_document.lambdas-ci.json
}
