variable "lariat_api_key" {
  type = string
}

variable "lariat_application_key" {
  type = string
}

variable "azure_region" {
  type = string
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
