resource "aws_lambda_function" "auto_cleanup" {
  count = var.auto_cleanup ? 1 : 0

  filename      = "cleanup.zip"
  function_name = "freetier-auto-cleanup-${random_string.test.result}"
  role          = aws_iam_role.lambda_role[0].arn
  handler       = "index.handler"
  runtime       = "python3.9"

  environment {
    variables = {
      USER_NAME = aws_iam_user.freetier.name
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  count = var.auto_cleanup ? 1 : 0

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_cloudwatch_event_rule" "cleanup_schedule" {
  count = var.auto_cleanup ? 1 : 0

  schedule_expression = "cron(0 * * * ? *)" # Every hour
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  count = var.auto_cleanup ? 1 : 0

  rule      = aws_cloudwatch_event_rule.cleanup_schedule[0].name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.auto_cleanup[0].arn
}