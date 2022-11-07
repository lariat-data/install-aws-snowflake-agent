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

resource snowsql_exec "lariat_snowflake_stage" {
  for_each = toset(var.snowflake_databases)
  name = "lariat-snowflake-stage-${each.key}"

  create {
    statements = <<-EOT
    USE DATABASE ${each.key};
    CREATE OR REPLACE STAGE lariat_stage;

    GRANT READ ON STAGE lariat_stage TO ROLE "${lower(snowflake_role.lariat_snowflake_role.name)}";
    EOT
  }

    delete {
    statements = <<-EOT
    USE DATABASE ${each.key};
    DROP STAGE IF EXISTS lariat_stage;
    EOT
  }
}

resource snowsql_exec "lariat_snowflake_sketch_udf_import" {
  for_each = toset(var.snowflake_databases)
  name = "lariat-snowflake-sketch-udf-import-${each.key}"
  depends_on = [
    snowsql_exec.lariat_snowflake_stage
  ]

  create {
    statements = <<-EOT
    put 'file://${path.cwd}/artifacts/java/agent-udfs-0.1-SNAPSHOT-jar-with-dependencies.jar' @${each.key}.lariat_stage auto_compress=false OVERWRITE=true;
    EOT
  }

    delete {
    statements = <<-EOT
    use database ${each.key};
    rm @lariat_stage pattern='.*agent-udfs-0.1-SNAPSHOT-jar-with-dependencies.jar.*';
    EOT
  }
}

resource snowsql_exec "lariat_snowflake_sketch_udf_create" {
  for_each = toset(var.snowflake_databases)
  name = "lariat-snowflake-sketch-udf-function-${each.key}"
  depends_on = [
    snowsql_exec.lariat_snowflake_sketch_udf_import
  ]

  create {
    statements = <<-EOT
    use database ${each.key};
    create or replace function hllpp_count_strings_sketch(x string)
    returns table(sketch binary)
    language java
    imports = ('@lariat_stage/agent-udfs-0.1-SNAPSHOT-jar-with-dependencies.jar')
    handler='com.lariat.agentudfs.HLPPCountStringsSketch';
    create or replace function hll_merge(x array)
    returns binary
    language java
    imports = ('@lariat_stage/agent-udfs-0.1-SNAPSHOT-jar-with-dependencies.jar')
    handler='com.lariat.agentudfs.HLPPMerge.merge';
    GRANT USAGE ON FUNCTION hllpp_count_strings_sketch(string) TO ROLE "${lower(snowflake_role.lariat_snowflake_role.name)}";
    GRANT USAGE ON FUNCTION hll_merge(array) TO ROLE "${lower(snowflake_role.lariat_snowflake_role.name)}";
    EOT
  }

    delete {
    statements = <<-EOT
    use database ${each.key};
    DROP FUNCTION IF EXISTS hllpp_count_strings_sketch(string);
    DROP FUNCTION IF EXISTS hll_merge(array);
    EOT
  }
}

output lariat_snowflake_user_password {
  value     = random_password.lariat_snowflake_user_password.result
  sensitive = true
}
