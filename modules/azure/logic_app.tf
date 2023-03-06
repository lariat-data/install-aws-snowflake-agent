# Contains app and recurrence definitions for an Azure Logic App,
# an Azure service that we use to trigger the Lariat Monitoring Function App
# at regular intervals

resource "azurerm_logic_app_workflow" "lariat_monitoring_workflow_schema_pull" {
  name                = "lariat-monitoring-workflow-schema-pull"
  location            = data.azurerm_resource_group.lariat_resource_group.location
  resource_group_name = data.azurerm_resource_group.lariat_resource_group.name
}

resource "azurerm_logic_app_action_custom" "lariat_raw_schema_action" {
  name = "lariat-raw-schema-action"
  logic_app_id = azurerm_logic_app_workflow.lariat_monitoring_workflow_schema_pull.id

  body = <<BODY
  {
    "inputs": {
        "body": {
            "run_type": "raw_schema"
        },
        "function": {
            "id": "${azurerm_linux_function_app.example.id}/functions/azure_snowflake_function"
        }
    },
    "runAfter": {},
    "type": "Function"
  }
  BODY
}

resource "azurerm_logic_app_trigger_recurrence" "lariat_daily_schema_pull" {
  name         = "lariat-daily-schema-pull"
  logic_app_id = azurerm_logic_app_workflow.lariat_monitoring_workflow_schema_pull.id
  frequency    = "Day"
  interval     = 1
  start_time =  timeadd(timestamp(), "7m")
}


resource "azurerm_logic_app_workflow" "lariat_monitoring_workflow_indicator_query" {
  name                = "lariat-monitoring-workflow-indicator-query"
  location            = data.azurerm_resource_group.lariat_resource_group.location
  resource_group_name = data.azurerm_resource_group.lariat_resource_group.name
}

resource "azurerm_logic_app_action_custom" "lariat_indicator_query_action" {
  name = "lariat-indicator-query-action"
  logic_app_id = azurerm_logic_app_workflow.lariat_monitoring_workflow_indicator_query.id

  body = <<BODY
  {
    "inputs": {
        "body": {
            "run_type": "batch_agent_query_dispatch"
        },
        "function": {
            "id": "${azurerm_linux_function_app.example.id}/functions/azure_snowflake_function"
        }
    },
    "runAfter": {},
    "type": "Function"
  }
  BODY
}

resource "azurerm_logic_app_trigger_recurrence" "lariat_daily_indicator_query" {
  name         = "lariat-frequent-indicator-query"
  logic_app_id = azurerm_logic_app_workflow.lariat_monitoring_workflow_indicator_query.id
  frequency    = "Minute"
  interval     = 5
}
