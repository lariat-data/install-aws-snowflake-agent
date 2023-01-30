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

variable "cloud" {
  type = string
}

variable "snowflake_account" {
  type = string
}

variable "snowflake_region" {
  type = string
}

variable "snowflake_user" {
  type = string
}

variable "snowflake_default_warehouse" {
  type = string
}

variable "snowflake_password" {
  type = string
  sensitive = true
}

variable "snowflake_databases" {
  type = list
}

variable "snowflake_account_locator" {
  type = string
}

variable "azure_region" {
  type = string
}
