
provider "aws" {
  region = "eu-west-1"
}

locals {
  name     = "samplesecret2-${uuid()}"
  filename = "secrets_manager_rotation.zip"
}

data "aws_caller_identity" "current" {}

data "aws_kms_alias" "secretsmanager" {
  name = "alias/aws/secretsmanager"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.name}iam-role-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}
resource "aws_lambda_function" "sample-mysql" {
  filename                       = "secrets_manager_rotation.zip"
  function_name                  = "secrets-manager-rotation"
  handler                        = "secrets_manager_rotation.lambda_handler"
  runtime                        = "python3.7"
  role                           = aws_iam_role.lambda.arn
  description                    = "AWS SecretsManager secret rotation for RDS MySQL using single user."
  source_code_hash               = filebase64sha256("${path.module}/${local.filename}")
  reserved_concurrent_executions = 0
  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "default" {
  function_name = aws_lambda_function.sample-mysql.function_name
  statement_id  = "AllowExecutionSecretManager"
  action        = "lambda:InvokeFunction"
  principal     = "secretsmanager.amazonaws.com"
}

resource "random_password" "rds_password" {
  length  = 16
  special = false
}

module "secretmanager_secret" {
  source                                = "./../"
  name                                  = local.name
  description                           = "this is a sample secret"
  kms_key_id                            = data.aws_kms_alias.secretsmanager.target_key_arn
  enable_secretsmanager_secret_rotation = true
  rotation_lambda_arn                   = aws_lambda_function.sample-mysql.arn
  enable_secretsmanager_secret_version  = true
  secret_string = jsonencode(
    {
      username = "admin"
      password = "${random_password.rds_password.result}"
      engine   = "mysql"
      port     = "3306"
  })
  enable_secretsmanager_secret_policy = true
  policy                              = <<POLICY
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "EnablePermissions",
          "Effect": "Allow",
          "Principal": {
            "AWS": "${data.aws_caller_identity.current.arn}"
          },         
          "Action": "secretsmanager:GetSecretValue",
          "Resource": "*"
        }
      ]
    }
    POLICY
}
