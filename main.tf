terraform {
  required_providers {
    snowflake = {
      source = "Snowflake-Labs/snowflake"
      version = "0.46.0"
    }
    snowsql = {
      source = "aidanmelen/snowsql"
      version = "1.0.1"
    }
    random = {
      source = "hashicorp/random"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

    time = {
      source  = "hashicorp/time"
    }
    null = {
      source  = "hashicorp/null"
    }
  }
}

locals {
    lariat_vendor_tag_aws = var.lariat_vendor_tag_aws != "" ? var.lariat_vendor_tag_aws : "lariat-${var.aws_region}"
}

provider "time" {}
provider "null" {}

# Configure default the AWS Provider
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      VendorLariat = local.lariat_vendor_tag_aws
    }
  }
}

resource "aws_iam_user" "lambda_create_user" {
  count = var.cloud == "aws" ? 1 : 0
  name = "lariat-snowflake-lambda-create-user"
}

resource "aws_iam_access_key" "lambda_create_user_keys" {
  count = var.cloud == "aws" ? 1 : 0
  user = aws_iam_user.lambda_create_user[count.index].name
}

provider "aws" {
  alias = "lambda_create_user"
  region = var.aws_region
  access_key = aws_iam_access_key.lambda_create_user_keys[0].id
  secret_key = aws_iam_access_key.lambda_create_user_keys[0].secret

  skip_credentials_validation = true
  skip_requesting_account_id = true
}

module "aws_snowflake_lariat_installation" {
  providers = {
    aws = aws
    aws.lambda_create_user = aws.lambda_create_user
  }

  source = "./modules/aws"
  count = var.cloud == "aws" ? 1 : 0

  # global config
  lariat_application_key = var.lariat_application_key
  lariat_api_key = var.lariat_api_key

  # cloud specific config
  s3_query_results_bucket = var.s3_query_results_bucket
  s3_agent_config_bucket = var.s3_agent_config_bucket
  aws_region = var.aws_region
  query_dispatch_interval_cron = var.query_dispatch_interval_cron
  lariat_vendor_tag_aws = var.lariat_vendor_tag_aws

  lambda_create_user_arn = aws_iam_user.lambda_create_user[count.index].arn
  lambda_create_user_name = aws_iam_user.lambda_create_user[count.index].name
  lariat_snowflake_user_name = snowflake_user.lariat_snowflake_user.name
  lariat_snowflake_user_password = random_password.lariat_snowflake_user_password.result
  lariat_snowflake_warehouse_name = snowflake_warehouse.lariat_snowflake_warehouse.name

  snowflake_account_locator = var.snowflake_account_locator
}
