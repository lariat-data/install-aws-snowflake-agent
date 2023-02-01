output "lariat_snowflake_warehouse_id" {
  value = "${snowflake_database.lariat_meta_database.id}"
}

output "lariat_snowflake_warehouse_name" {
  value = "${snowflake_database.lariat_meta_database.name}"
}

output "lariat_meta_db_schema_database" {
  value = "${snowflake_schema.lariat_meta_database.database}"
}

output "lariat_meta_db_schema_database_name" {
  value = "${snowflake_schema.lariat_meta_database.name}"
}

output "lariat_snowflake_role_name" {
  value = "${snowflake_role.lariat_snowflake_role.name}"
}

output "lariat_snowflake_user_name" {
  value = "${snowflake_user.lariat_snowflake_user.name}"
}

output "lariat_snowflake_user_email" {
  value = "${snowflake_user.lariat_snowflake_user.email}"
}

output "lariat_snowflake_user_password" {
  value = "${snowflake_user.lariat_snowflake_user.password}"
  sensitive = true
}

