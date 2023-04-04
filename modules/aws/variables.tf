variable "lariat_api_key" {
  type = string
}

variable "lariat_application_key" {
  type = string
}

variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "s3_query_results_bucket" {
  type = string
}

variable "s3_agent_config_bucket" {
  type = string
}

variable "query_dispatch_interval_cron" {
  type = string
}

variable "lariat_vendor_tag_aws" {
  type = string
  default = ""
}

variable "lambda_create_user_arn" {
  type = string
}

variable "lambda_create_user_name" {
  type = string
}

variable "lariat_snowflake_user_name" {
  type = string
}

variable "lariat_snowflake_user_password" {
  type = string
}

variable "lariat_snowflake_warehouse_name" {
  type = string
}

variable "lariat_snowflake_meta_db_name" {
  type = string
}

variable "lariat_snowflake_meta_schema_name" {
  type = string
}

variable "snowflake_account" {
  type = string
}
