variable "lariat_api_key" {
  type = string
}

variable "lariat_application_key" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "s3_query_results_bucket" {
  type = string
  default = "lariat-snowflak-default-query-results"
}

variable "s3_agent_config_bucket" {
  type = string
  default = "lariat-snowflake-default-config"
}

variable "query_dispatch_interval_cron" {
  type = string
  default = "rate(5 minutes)"
}

variable "lariat_vendor_tag_aws" {
  type = string
  default = ""
}

variable "cloud" {
  type = string
  default = "aws"
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
