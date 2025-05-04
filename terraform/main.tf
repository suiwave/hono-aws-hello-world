############################################################################
## terraformブロック
############################################################################
terraform {
  # Terraformのバージョン指定
  required_version = "~> 1.7.0"

  # Terraformのaws用ライブラリのバージョン指定
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.33.0"
    }
  }
}

############################################################################
## providerブロック
############################################################################
provider "aws" {
  # リージョンを指定
  region = "ap-northeast-1"
}

locals {
  project = "hono_aws_hello_world"
  dir_path = "${path.module}/../function/dist"
}

############################################################################
## lambda
############################################################################
/* lambda実行ロール */
# lambda用AWSマネージドポリシーを準備
# ロギング用ポリシードキュメント
data "aws_iam_policy_document" "logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }
}

# ロギング用ポリシー
resource "aws_iam_policy" "logging" {
  name        = "lambda-logging-policy"
  description = "IAM policy for Lambda to write logs to CloudWatch"
  policy      = data.aws_iam_policy_document.logging.json
}

# lambda assume用ポリシードキュメント
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# lambda用IAMロール作成
resource "aws_iam_role" "lambda_execution_role" {
  name               = "my-lambda-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# lambda用IAMロールへポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "lambda_logs_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.logging.arn
}

# ロググループを作成
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.project}_lambda"
  retention_in_days = 14
}

# zipを作成
data "archive_file" "lambda_my_function" {
  type             = "zip"
  output_file_mode = "0666"
  source_dir       = local.dir_path
  output_path      = "${local.dir_path}.zip"
}

/* lambda関数 */
resource "aws_lambda_function" "lambda" {
  function_name = "${local.project}_lambda"
  role          = aws_iam_role.lambda_execution_role.arn

  runtime  = "nodejs20.x" # TODO:Terraform古い
  filename = data.archive_file.lambda_my_function.output_path
  handler  = "handler.handler"

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.lambda.name
  }

  # Terraformに変更を無視させるため、lifecycle ルールを追加
  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

# # 関数 URL
# resource "aws_lambda_function_url" "public_url" {
#   function_name      = aws_lambda_function.lambda.function_name
#   authorization_type = "NONE"
# }

# # Function URL経由での呼び出しを許可 (authorization_type = "NONE" の場合必須)
# resource "aws_lambda_permission" "allow_public_access" {
#   statement_id  = "AllowPublicAccessToFunctionUrl"
#   action        = "lambda:InvokeFunctionUrl"
#   function_name = aws_lambda_function.lambda.function_name
#   principal     = "*"
#   function_url_auth_type = "NONE"

#   # Function URLが作成された後に権限を付与
#   depends_on = [aws_lambda_function_url.public_url]
# }