output "lariat_lambda_create_user_kms_arn" {
  value = "${aws_kms_key.lambda_create_user_kms.arn}"
}

output "lariat_lambda_create_user_kms_key_id" {
  value = "${aws_kms_key.lambda_create_user_kms.key_id}"
}

output "lariat_lambda_create_user_policy_arn" {
  value = "${aws_iam_user_policy.lambda_create_user_policy.arn}"
}

output "lariat_lambda_create_user_policy_id" {
  value = "${aws_iam_user_policy.lambda_create_user_policy.id}"
}

output "lariat_snowflake_agent_config_bucket_arn" {
  value = "${aws_s3_bucket.lariat_snowflake_agent_config_bucket.arn}"
}

output "lariat_snowflake_agent_config_bucket_id" {
  value = "${aws_s3_bucket.lariat_snowflake_agent_config_bucket.id}"
}

output "lariat_snowflake_agent_config_bucket_regional_domain_name" {
  value = "${aws_s3_bucket.lariat_snowflake_agent_config_bucket.bucket_regional_domain_name}"
}

output "lariat_snowflake_query_results_bucket_arn" {
  value = "${aws_s3_bucket.lariat_snowflake_query_results_bucket.arn}"
}

output "lariat_snowflake_query_results_bucket_id" {
  value = "${aws_s3_bucket.lariat_snowflake_query_results_bucket.id}"
}

output "lariat_snowflake_query_results_bucket_regional_domain_name" {
  value = "${aws_s3_bucket.lariat_snowflake_query_results_bucket.bucket_regional_domain_name}"
}

output "lariat_snowflake_agent_config_id" {
  value = "${aws_s3_object.lariat_snowflake_agent_config.id}"
}

output "lariat_snowflake_agent_config_etag" {
  value = "${aws_s3_object.lariat_snowflake_agent_config.etag}"
}

output "lariat_snowflake_monitoring_policy_arn" {
  value = "${aws_iam_user_policy.lariat_snowflake_monitoring_policy.arn}"
}

output "lariat_snowflake_monitoring_policy_id" {
  value = "${aws_iam_user_policy.lariat_snowflake_monitoring_policy.id}"
}

output "lariat_snowflake_monitoring_lambda_role_arn" {
  value = "${aws_iam_role.lariat_snowflake_monitoring_lambda_role.arn}"
}

output "lariat_snowflake_monitoring_lambda_role_id" {
  value = "${aws_iam_role.lariat_snowflake_monitoring_lambda_role.id}"
}

output "lariat_snowflake_monitoring_lambda_arn" {
  value = "${aws_lambda_function.lariat_snowflake_monitoring_lambda.arn}"
}

output "lariat_snowflake_monitoring_lambda_version" {
  value = "${aws_lambda_function.lariat_snowflake_monitoring_lambda.version}"
}

output "lariat_snowflake_monitoring_lambda_size" {
  value = "${aws_lambda_function.lariat_snowflake_monitoring_lambda.source_code_size}"
}

output "lariat_snowflake_lambda_trigger_5_minutely_arn" {
  value = "${aws_cloudwatch_event_rule.lariat_snowflake_lambda_trigger_5_minutely.arn}"
}

output "lariat_snowflake_lambda_trigger_5_minutely_id" {
  value = "${aws_cloudwatch_event_rule.lariat_snowflake_lambda_trigger_5_minutely.id}"
}

output "lariat_snowflake_lambda_trigger_daily_arn" {
  value = "${aws_cloudwatch_event_rule.lariat_snowflake_lambda_trigger_daily.arn}"
}

output "lariat_snowflake_lambda_trigger_daily_id" {
  value = "${aws_cloudwatch_event_rule.lariat_snowflake_lambda_trigger_daily.id}"
}

output "lariat_snowflake_lambda_trigger_heartbeat_arn" {
  value = "${aws_cloudwatch_event_rule.lariat_snowflake_lambda_trigger_heartbeat.arn}"
}

output "lariat_snowflake_lambda_trigger_heartbeat_id" {
  value = "${aws_cloudwatch_event_rule.lariat_snowflake_lambda_trigger_heartbeat.id}"
}
