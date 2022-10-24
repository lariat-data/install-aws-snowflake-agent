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

resource "azurerm_linux_function_app" "example" {
  name                = "lariat-monitoring-linux-function"
  resource_group_name = azurerm_resource_group.lariat_resource_group.name
  location            = azurerm_resource_group.lariat_resource_group.location

  storage_account_name       = azurerm_storage_account.lariat_storage_account.name
  storage_account_access_key = azurerm_storage_account.lariat_storage_account.primary_access_key

  service_plan_id            = azurerm_service_plan.lariat_app_service_plan.id

  site_config {
    application_stack {
      docker {
        registry_url = "hub.docker.com"
        image_name = "talwai/azurefunctionsimage"
        image_tag = "v1.0.0"
      }
    }
  }
}

