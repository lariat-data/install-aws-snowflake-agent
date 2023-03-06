# Create a resource group
data "azurerm_resource_group" "lariat_resource_group" {
  name     = "lariat-resource-group"
}


resource "azurerm_service_plan" "lariat_app_service_plan" {
  name                = "lariat-app-service-plan"
  resource_group_name = data.azurerm_resource_group.lariat_resource_group.name
  location            = data.azurerm_resource_group.lariat_resource_group.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_storage_account" "lariat_storage_account" {
  name                     = "lariatstorageaccount"
  resource_group_name      = data.azurerm_resource_group.lariat_resource_group.name
  location                 = data.azurerm_resource_group.lariat_resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "lariat_storage_container" {
  name = "lariat-storage-container"
  storage_account_name = azurerm_storage_account.lariat_storage_account.name
}

resource "azurerm_storage_blob" "lariat_snowflake_agent_config" {
  name                   = "lariat_snowflake_agent_config.yaml"
  storage_account_name   = azurerm_storage_account.lariat_storage_account.name
  storage_container_name = azurerm_storage_container.lariat_storage_container.name
  type                   = "Block"
  source                 = "config/snowflake_agent.yaml"
  content_md5            = filemd5("config/snowflake_agent.yaml")
}

resource "azurerm_application_insights" "lariat_application_insights" {
  name                = "lariat-monitoring-appinsights"
  location            = data.azurerm_resource_group.lariat_resource_group.location
  resource_group_name = data.azurerm_resource_group.lariat_resource_group.name
  application_type    = "web"
}

resource "azurerm_linux_function_app" "example" {
  name                = "lariat-monitoring-linux-function"
  resource_group_name = data.azurerm_resource_group.lariat_resource_group.name
  location            = data.azurerm_resource_group.lariat_resource_group.location

  storage_account_name       = azurerm_storage_account.lariat_storage_account.name
  storage_account_access_key = azurerm_storage_account.lariat_storage_account.primary_access_key

  service_plan_id            = azurerm_service_plan.lariat_app_service_plan.id
  builtin_logging_enabled = true

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    AZURE_STORAGE_CONTAINER = azurerm_storage_container.lariat_storage_container.name
    AZURE_STORAGE_CONNECTION_STRING = azurerm_storage_account.lariat_storage_account.primary_blob_connection_string
    CLOUD_AGENT_CONFIG_PATH = azurerm_storage_blob.lariat_snowflake_agent_config.name

    LARIAT_API_KEY = var.lariat_api_key
    LARIAT_APPLICATION_KEY = var.lariat_application_key

    SNOWFLAKE_ACCOUNT =  "${var.snowflake_account_locator}"
    SNOWFLAKE_USER = "${var.lariat_snowflake_user_name}"
    SNOWFLAKE_PASSWORD = "${var.lariat_snowflake_user_password}"
    SNOWFLAKE_WAREHOUSE = "${var.lariat_snowflake_warehouse_name}"
  }

  site_config {
    always_on = true
    application_insights_connection_string = azurerm_application_insights.lariat_application_insights.connection_string
    application_insights_key = azurerm_application_insights.lariat_application_insights.instrumentation_key

    application_stack {
      docker {
        registry_url = "docker.io"
        image_name = "vikaslariat/lariat-snowflake-azure"
        image_tag = "latest"
        registry_username = "vikaslariat"
        registry_password = "lariatsnowflake"
      }
    }

    app_service_logs {
      disk_quota_mb = 35
    }
  }

  lifecycle {
    ignore_changes = [
      tags["hidden-link: /app-insights-instrumentation-key"],
      tags["hidden-link: /app-insights-conn-string"],
      tags["hidden-link: /app-insights-resource-id"]
    ]
  }
}
