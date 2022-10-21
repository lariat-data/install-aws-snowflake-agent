provider "snowsql" {
  username = var.snowflake_user
  password = var.snowflake_password
  account = var.snowflake_account
  region = var.snowflake_region
  warehouse = var.snowflake_default_warehouse
  role   = "accountadmin"
}

provider "snowflake" {
  username = var.snowflake_user
  password = var.snowflake_password
  account = var.snowflake_account
  region = var.snowflake_region
  warehouse = var.snowflake_default_warehouse
  role   = "accountadmin"
}

resource snowflake_warehouse "lariat_snowflake_warehouse" {
  name           = "lariat_snowflake_warehouse"
  comment        = "warehouse for running lariat monitoring queries"
  warehouse_size = "xsmall"
  initially_suspended = true
  auto_suspend = 60 # suspend after 60 seconds of inactivity
  auto_resume = true
}

resource snowflake_role "lariat_snowflake_role" {
  name           = "lariat_snowflake_role"
  comment        = "role for running lariat monitoring queries"
}

resource snowflake_warehouse_grant "lariat_snowflake_warehouse_grant_operate" {
  warehouse_name = "${snowflake_warehouse.lariat_snowflake_warehouse.name}"
  privilege = "OPERATE"

  roles = [
    "${snowflake_role.lariat_snowflake_role.name}"
  ]

  with_grant_option = false
}

resource snowflake_warehouse_grant "lariat_snowflake_warehouse_grant_usage" {
  warehouse_name = "${snowflake_warehouse.lariat_snowflake_warehouse.name}"
  privilege = "USAGE"

  roles = [
    "${snowflake_role.lariat_snowflake_role.name}"
  ]

  with_grant_option = false
}

resource snowflake_warehouse_grant "lariat_snowflake_warehouse_grant_monitor" {
  warehouse_name = "${snowflake_warehouse.lariat_snowflake_warehouse.name}"
  privilege = "MONITOR"

  roles = [
    "${snowflake_role.lariat_snowflake_role.name}"
  ]

  with_grant_option = false
}

resource "random_password" "lariat_snowflake_user_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource snowflake_user "lariat_snowflake_user" {
  name           = "lariat_snowflake_user"
  password       = random_password.lariat_snowflake_user_password.result
  comment        = "user for running lariat monitoring queries"

  default_warehouse = snowflake_warehouse.lariat_snowflake_warehouse.name
  default_role = snowflake_role.lariat_snowflake_role.name
}

resource snowflake_role_grants "lariat_snowflake_grants" {
  role_name = "${snowflake_role.lariat_snowflake_role.name}"

  users = [
    "${snowflake_user.lariat_snowflake_user.name}"
  ]
}

resource snowsql_exec "lariat_read_only_grants" {
  for_each = toset(var.snowflake_databases)
  name = "lariat-read-only-grants-${each.key}"
  depends_on = [
    snowflake_role_grants.lariat_snowflake_grants
  ]

  create {
    statements = <<-EOT
    GRANT USAGE ON DATABASE ${each.key} TO ROLE "${lower(snowflake_role.lariat_snowflake_role.name)}";
    GRANT USAGE ON ALL SCHEMAS IN DATABASE ${each.key} TO ROLE "${lower(snowflake_role.lariat_snowflake_role.name)}";
    GRANT SELECT ON ALL TABLES IN DATABASE ${each.key} TO ROLE "${lower(snowflake_role.lariat_snowflake_role.name)}";
    GRANT SELECT ON FUTURE TABLES IN DATABASE ${each.key} TO ROLE "${lower(snowflake_role.lariat_snowflake_role.name)}";
    EOT
  }

    delete {
    statements = <<-EOT
    REVOKE USAGE ON DATABASE ${each.key} FROM ROLE "${lower(snowflake_role.lariat_snowflake_role.name)}";
    REVOKE USAGE ON ALL SCHEMAS IN DATABASE ${each.key} FROM ROLE "${lower(snowflake_role.lariat_snowflake_role.name)}";
    REVOKE ALL PRIVILEGES ON ALL TABLES IN DATABASE ${each.key} FROM ROLE "${lower(snowflake_role.lariat_snowflake_role.name)}";
    REVOKE ALL PRIVILEGES ON FUTURE TABLES IN DATABASE ${each.key} FROM ROLE "${lower(snowflake_role.lariat_snowflake_role.name)}";
    EOT
  }
}

output lariat_snowflake_user_password {
  value     = random_password.lariat_snowflake_user_password.result
  sensitive = true
}
