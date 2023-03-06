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
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.28.0"
    }
    time = {
      source  = "hashicorp/time"
    }
    null = {
      source  = "hashicorp/null"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "time" {}
provider "null" {}

module "azure_snowflake_lariat_installation" {
  source = "./modules/azure"
  count = var.cloud == "azure" ? 1 : 0

  lariat_application_key = var.lariat_application_key
  lariat_api_key = var.lariat_api_key
  lariat_snowflake_user_name = snowflake_user.lariat_snowflake_user.name
  lariat_snowflake_user_password = random_password.lariat_snowflake_user_password.result
  lariat_snowflake_warehouse_name = snowflake_warehouse.lariat_snowflake_warehouse.name

  lariat_snowflake_meta_db_name = snowflake_database.lariat_meta_database.name
  lariat_snowflake_meta_schema_name = snowflake_schema.lariat_meta_db_schema.name

  snowflake_account_locator = var.snowflake_account_locator
  azure_region = var.azure_region
}
