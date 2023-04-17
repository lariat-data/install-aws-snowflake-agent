locals {
    today  = timestamp()
    lambda_heartbeat_time   = timeadd(local.today, "5m")
    lambda_heartbeat_minute = formatdate("m", local.lambda_heartbeat_time)
    lambda_heartbeat_hour = formatdate("h", local.lambda_heartbeat_time)
    lambda_heartbeat_day = formatdate("D", local.lambda_heartbeat_time)
    lambda_heartbeat_month = formatdate("M", local.lambda_heartbeat_time)
    lambda_heartbeat_year = formatdate("YYYY", local.lambda_heartbeat_time)
    lariat_vendor_tag_aws = var.lariat_vendor_tag_aws != "" ? var.lariat_vendor_tag_aws : "lariat-${var.aws_region}"
}

data "aws_caller_identity" "current" {}

# Configure the alternate AWS Provider used for lambda.CreateFunction
data "aws_iam_policy_document" "lariat_lambda_kms_create_user_key_policy" {
  statement {
    actions = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    actions = [
      "kms:CreateGrant",
      "kms:GenerateDataKey",
      "kms:Encrypt",
      "kms:Decrypt"
    ]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [var.lambda_create_user_arn]
    }
  }
}

resource "aws_kms_key" "lambda_create_user_kms" {
  description = "A key allowing the lambda create user to encrypt/decrypt env vars"
  policy = data.aws_iam_policy_document.lariat_lambda_kms_create_user_key_policy.json
}

data "aws_iam_policy_document" "lariat_lambda_create_user_policy" {
  statement {
    actions = [
        "kms:ListKeys",
        "kms:ListAliases",
        "kms:CreateGrant",
        "kms:GenerateDataKey",
    ]

    resources = [aws_kms_key.lambda_create_user_kms.arn]
  }

  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]

    resources = ["arn:aws:ecr:${var.aws_region}:358681817243:repository/lariat-snowflake-agent"]
  }
}

resource "aws_iam_user_policy" "lambda_create_user_policy" {
  name = "lariat-snowflake-lambda-create-user"
  user = var.lambda_create_user_name
  policy = data.aws_iam_policy_document.lariat_lambda_create_user_policy.json
}

resource "aws_iam_user_policy_attachment" "lambda_create_user_lambda_access" {
  user = var.lambda_create_user_name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

resource "aws_iam_user_policy_attachment" "lambda_create_user_ecr_access" {
  user = var.lambda_create_user_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_s3_bucket" "lariat_snowflake_agent_config_bucket" {
  bucket_prefix = var.s3_agent_config_bucket
  force_destroy = true
}

resource "aws_s3_bucket" "lariat_snowflake_query_results_bucket" {
  bucket_prefix = var.s3_query_results_bucket
  force_destroy = true
}

resource "aws_s3_object" "lariat_snowflake_agent_config" {
  bucket = aws_s3_bucket.lariat_snowflake_agent_config_bucket.bucket
  key    = "snowflake_agent.yaml"
  source = "snowflake_agent.yaml"

  etag = filemd5("snowflake_agent.yaml")
}

data "aws_iam_policy_document" "lariat_snowflake_agent_repository_policy" {
  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy"
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "lariat_snowflake_monitoring_policy" {
  name_prefix = "lariat-snowflake-monitoring-policy"
  policy = templatefile("iam/lariat-snowflake-monitoring-policy.json.tftpl", { s3_query_results_bucket = aws_s3_bucket.lariat_snowflake_query_results_bucket.bucket, s3_agent_config_bucket = aws_s3_bucket.lariat_snowflake_agent_config_bucket.bucket, aws_account_id = data.aws_caller_identity.current.account_id })
}

data "aws_iam_policy_document" "lambda-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lariat_snowflake_monitoring_lambda_role" {
  name_prefix = "lariat-snowflak-monitoring-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role-policy.json
  managed_policy_arns = [aws_iam_policy.lariat_snowflake_monitoring_policy.arn, "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

# This resource will destroy (potentially immediately) after null_resource.next
resource "null_resource" "previous" {}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [null_resource.previous]

  create_duration = "30s"
}

resource "aws_lambda_function" "lariat_snowflake_monitoring_lambda" {
  depends_on = [time_sleep.wait_30_seconds]

  provider = aws.lambda_create_user

  function_name = "lariat-snowflake-monitoring-lambda"
  image_uri = "358681817243.dkr.ecr.${var.aws_region}.amazonaws.com/lariat-snowflake-agent:latest"
  role = aws_iam_role.lariat_snowflake_monitoring_lambda_role.arn
  package_type = "Image"
  memory_size = 512
  timeout = 900

  tags = {
    VendorLariat = local.lariat_vendor_tag_aws
  }

  environment {
    variables = {
      S3_QUERY_RESULTS_BUCKET = aws_s3_bucket.lariat_snowflake_query_results_bucket.bucket
      LARIAT_API_KEY = var.lariat_api_key
      LARIAT_APPLICATION_KEY = var.lariat_application_key
      S3_AGENT_CONFIG_PATH = "${aws_s3_bucket.lariat_snowflake_agent_config_bucket.bucket}/snowflake_agent.yaml"
      CLOUD_AGENT_CONFIG_PATH = "${aws_s3_bucket.lariat_snowflake_agent_config_bucket.bucket}/snowflake_agent.yaml"
      LARIAT_ENDPOINT = "http://ingest.lariatdata.com/api"
      LARIAT_OUTPUT_BUCKET = "lariat-batch-agent-sink"

      SNOWFLAKE_ACCOUNT =  "${var.snowflake_account}"
      SNOWFLAKE_USER = "${var.lariat_snowflake_user_name}"
      SNOWFLAKE_PASSWORD = "${var.lariat_snowflake_user_password}"
      SNOWFLAKE_WAREHOUSE = "${var.lariat_snowflake_warehouse_name}"

      LARIAT_META_DB = "${var.lariat_snowflake_meta_db_name}"
      LARIAT_META_SCHEMA = "${var.lariat_snowflake_meta_schema_name}"
    }
  }
}

resource "aws_lambda_function_event_invoke_config" "lariat_snowflake_monitoring_lambda_config" {
  function_name = aws_lambda_function.lariat_snowflake_monitoring_lambda.function_name
  maximum_retry_attempts = 0
}

resource "aws_cloudwatch_event_rule" "lariat_snowflake_lambda_trigger_5_minutely" {
  name_prefix = "lariat-snowflake-lambda-trigger"
  schedule_expression = var.query_dispatch_interval_cron
}

resource "aws_cloudwatch_event_rule" "lariat_snowflake_lambda_trigger_daily" {
  name_prefix = "lariat-snowflake-lambda-trigger"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "lariat_snowflake_lambda_trigger_5_minutely_target" {
  rule = aws_cloudwatch_event_rule.lariat_snowflake_lambda_trigger_5_minutely.name
  arn = aws_lambda_function.lariat_snowflake_monitoring_lambda.arn
  input = jsonencode({"run_type"="batch_agent_query_dispatch"})
}

resource "aws_cloudwatch_event_target" "lariat_snowflake_lambda_trigger_daily_target" {
  rule = aws_cloudwatch_event_rule.lariat_snowflake_lambda_trigger_daily.name
  arn = aws_lambda_function.lariat_snowflake_monitoring_lambda.arn
  input = jsonencode({"run_type"="raw_schema"})
}

resource "aws_cloudwatch_event_rule" "lariat_snowflake_lambda_trigger_heartbeat" {
  name_prefix = "lariat-snowflake-lambda-trigger"
  schedule_expression ="cron(${local.lambda_heartbeat_minute} ${local.lambda_heartbeat_hour} ${local.lambda_heartbeat_day} ${local.lambda_heartbeat_month} ? ${local.lambda_heartbeat_year})"
}

resource "aws_cloudwatch_event_target" "lariat_snowflake_lambda_trigger_heartbeat_target" {
  rule = aws_cloudwatch_event_rule.lariat_snowflake_lambda_trigger_heartbeat.name
  arn = aws_lambda_function.lariat_snowflake_monitoring_lambda.arn
  input = jsonencode({"run_type"="raw_schema"})
}

resource "aws_lambda_permission" "allow_cloudwatch_5_minutely" {
  statement_id  = "AllowExecutionFromCloudWatch5Minutely"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lariat_snowflake_monitoring_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lariat_snowflake_lambda_trigger_5_minutely.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_daily" {
  statement_id  = "AllowExecutionFromCloudWatchDaily"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lariat_snowflake_monitoring_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lariat_snowflake_lambda_trigger_daily.arn
}


resource "aws_lambda_permission" "allow_cloudwatch_heartbeat" {
  statement_id  = "AllowExecutionFromCloudWatchHeartbeat"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lariat_snowflake_monitoring_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lariat_snowflake_lambda_trigger_heartbeat.arn
}

data "aws_iam_policy_document" "allow_access_from_lariat_account" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["358681817243"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.lariat_snowflake_query_results_bucket.arn,
      "${aws_s3_bucket.lariat_snowflake_query_results_bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_lariat_account_policy" {
  bucket = aws_s3_bucket.lariat_snowflake_query_results_bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_lariat_account.json
}
