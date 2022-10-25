# Create a resource group
resource "azurerm_resource_group" "lariat_resource_group" {
  name     = "lariat-resource-group"
  location = var.azure_region
}


resource "azurerm_service_plan" "lariat_app_service_plan" {
  name                = "lariat-app-service-plan"
  resource_group_name = azurerm_resource_group.lariat_resource_group.name
  location            = azurerm_resource_group.lariat_resource_group.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_storage_account" "lariat_storage_account" {
  name                     = "lariatstorageaccount"
  resource_group_name      = azurerm_resource_group.lariat_resource_group.name
  location                 = azurerm_resource_group.lariat_resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_application_insights" "lariat_application_insights" {
  name                = "lariat-monitoring-appinsights"
  location            = azurerm_resource_group.lariat_resource_group.location
  resource_group_name = azurerm_resource_group.lariat_resource_group.name
  application_type    = "web"
}

resource "azurerm_linux_function_app" "example" {
  name                = "lariat-monitoring-linux-function"
  resource_group_name = azurerm_resource_group.lariat_resource_group.name
  location            = azurerm_resource_group.lariat_resource_group.location

  storage_account_name       = azurerm_storage_account.lariat_storage_account.name
  storage_account_access_key = azurerm_storage_account.lariat_storage_account.primary_access_key

  service_plan_id            = azurerm_service_plan.lariat_app_service_plan.id
  builtin_logging_enabled = true

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
  }

  site_config {
    always_on = true
    application_insights_connection_string = azurerm_application_insights.lariat_application_insights.connection_string
    application_insights_key = azurerm_application_insights.lariat_application_insights.instrumentation_key

    application_stack {
      docker {
        registry_url = "docker.io"
        image_name = "vikaslariat/lariat-snowflake-azure"
        image_tag = "tested"
        registry_username = "vikaslariat"
        registry_password = "lariatsnowflake"
      }
    }

    app_service_logs {
      disk_quota_mb = 35
    }

  }
}

