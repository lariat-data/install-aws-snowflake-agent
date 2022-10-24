import argparse
import sys
import os
import json
import subprocess
import snowflake.connector


SNOWFLAKE_WAREHOUSE = "COMPUTE_WH"
SNOWFLAKE_ACCOUNT_LOCATOR="CL46984.us-east-2.aws"
SNOWFLAKE_REGION="us-east-2.aws"
SNOWFLAKE_ACCOUNT="CL46984"
SNOWFLAKE_USER="aaditya"
SNOWFLAKE_PASSWORD=os.environ.get("SNOWFLAKE_PASSWORD")
SNOWFLAKE_DATABASE_ALLOWLIST = ["LARIAT_SNOWFLAKE_TEST"]

LARIAT_API_KEY="162814e3ec2236e9e557ac8aa87a44cf"
LARIAT_APPLICATION_KEY="28488da99d7842c6494aeaf4bf95251b"
S3_QUERY_RESULTS_BUCKET="lariat-snowflak-default-query-results"
S3_AGENT_CONFIG_BUCKET="lariat-snowflake-default-config"
QUERY_DISPATCH_INTERVAL_CRON="cron(48 * * * ? *)"

AWS_REGION="us-east-2"
AZURE_REGION = "Central US"

def get_snowflake_databases():
    con = snowflake.connector.connect(
            user=SNOWFLAKE_USER,
            account=SNOWFLAKE_ACCOUNT_LOCATOR,
            password=SNOWFLAKE_PASSWORD,
            role="ACCOUNTADMIN",
    )

    cur = con.cursor()
    result = cur.execute("SHOW DATABASES")
    databases = [r[1] for r in result]

    return databases

def install_lariat_to_databases(cloud="aws"):
    dbs = get_snowflake_databases()
    filtered_dbs = [db for db in dbs if db.upper() in SNOWFLAKE_DATABASE_ALLOWLIST]
    if not filtered_dbs:
        print(f"No valid database found for Lariat installation")
        return

    print(f"Installing lariat to Snowflake Databases {filtered_dbs}")
    tf_env = {
        "TF_VAR_snowflake_account": SNOWFLAKE_ACCOUNT,
        "TF_VAR_snowflake_default_warehouse": SNOWFLAKE_WAREHOUSE,
        "TF_VAR_snowflake_user": SNOWFLAKE_USER,
        "TF_VAR_snowflake_region": SNOWFLAKE_REGION,
        "TF_VAR_snowflake_password": SNOWFLAKE_PASSWORD,
        "TF_VAR_snowflake_databases": f'{json.dumps(filtered_dbs)}',
        "TF_VAR_snowflake_account_locator": SNOWFLAKE_ACCOUNT_LOCATOR,

        "TF_VAR_lariat_api_key": LARIAT_API_KEY,
        "TF_VAR_lariat_application_key": LARIAT_APPLICATION_KEY,
        "TF_VAR_s3_query_results_bucket": S3_QUERY_RESULTS_BUCKET,
        "TF_VAR_s3_agent_config_bucket": S3_AGENT_CONFIG_BUCKET,
        "TF_VAR_query_dispatch_interval_cron": QUERY_DISPATCH_INTERVAL_CRON,
        "TF_VAR_aws_region": AWS_REGION,
        "TF_VAR_cloud": cloud,
        "TF_VAR_azure_region": AZURE_REGION,
    }

    my_env = os.environ.copy()
    for k, v in tf_env.items(): my_env[k] = v

    subprocess.run(["terraform", "apply"], env=my_env)

def destroy_lariat_installations(cloud="aws"):
    dbs = get_snowflake_databases()
    filtered_dbs = [db for db in dbs if db.upper() in SNOWFLAKE_DATABASE_ALLOWLIST]
    if not filtered_dbs:
        print(f"No valid database found for Lariat installation")
        return

    print(f"Removing lariat from Snowflake Databases {filtered_dbs}")
    tf_env = {
        "TF_VAR_snowflake_account": SNOWFLAKE_ACCOUNT,
        "TF_VAR_snowflake_default_warehouse": SNOWFLAKE_WAREHOUSE,
        "TF_VAR_snowflake_user": SNOWFLAKE_USER,
        "TF_VAR_snowflake_region": SNOWFLAKE_REGION,
        "TF_VAR_snowflake_password": SNOWFLAKE_PASSWORD,
        "TF_VAR_snowflake_databases": f'{json.dumps(filtered_dbs)}',
        "TF_VAR_snowflake_account_locator": SNOWFLAKE_ACCOUNT_LOCATOR,

        "TF_VAR_lariat_api_key": LARIAT_API_KEY,
        "TF_VAR_lariat_application_key": LARIAT_APPLICATION_KEY,
        "TF_VAR_s3_query_results_bucket": S3_QUERY_RESULTS_BUCKET,
        "TF_VAR_s3_agent_config_bucket": S3_AGENT_CONFIG_BUCKET,
        "TF_VAR_query_dispatch_interval_cron": QUERY_DISPATCH_INTERVAL_CRON,
        "TF_VAR_aws_region": AWS_REGION,
        "TF_VAR_cloud": cloud,
        "TF_VAR_azure_region": AZURE_REGION,
    }

    my_env = os.environ.copy()
    for k, v in tf_env.items(): my_env[k] = v

    subprocess.run(["terraform", "destroy"], env=my_env)

def plan_lariat_installation(cloud="aws"):
    dbs = get_snowflake_databases()
    filtered_dbs = [db for db in dbs if db.upper() in SNOWFLAKE_DATABASE_ALLOWLIST]
    if not filtered_dbs:
        print(f"No valid database found for Lariat installation")
        return

    print(f"Planning lariat installation to Snowflake Databases {filtered_dbs}")
    tf_env = {
        "TF_VAR_snowflake_account": SNOWFLAKE_ACCOUNT,
        "TF_VAR_snowflake_default_warehouse": SNOWFLAKE_WAREHOUSE,
        "TF_VAR_snowflake_user": SNOWFLAKE_USER,
        "TF_VAR_snowflake_region": SNOWFLAKE_REGION,
        "TF_VAR_snowflake_password": SNOWFLAKE_PASSWORD,
        "TF_VAR_snowflake_databases": f'{json.dumps(filtered_dbs)}',
        "TF_VAR_snowflake_account_locator": SNOWFLAKE_ACCOUNT_LOCATOR,

        "TF_VAR_lariat_api_key": LARIAT_API_KEY,
        "TF_VAR_lariat_application_key": LARIAT_APPLICATION_KEY,
        "TF_VAR_s3_query_results_bucket": S3_QUERY_RESULTS_BUCKET,
        "TF_VAR_s3_agent_config_bucket": S3_AGENT_CONFIG_BUCKET,
        "TF_VAR_query_dispatch_interval_cron": QUERY_DISPATCH_INTERVAL_CRON,
        "TF_VAR_aws_region": AWS_REGION,
        "TF_VAR_cloud": cloud,
        "TF_VAR_azure_region": AZURE_REGION,
    }

    my_env = os.environ.copy()
    for k, v in tf_env.items(): my_env[k] = v

    subprocess.run(["terraform", "plan"], env=my_env)

def main():
    parser = argparse.ArgumentParser(description='Manage a Lariat Snowflake Installation')
    parser.add_argument('--action', choices=['plan', 'apply', 'destroy'])
    parser.add_argument('--cloud', choices=['aws', 'azure'])
    ns = parser.parse_args(sys.argv[1:])

    if ns.action == 'destroy':
        func = destroy_lariat_installations
    elif ns.action == 'plan':
        func = plan_lariat_installation
    elif ns.action == 'apply':
        func = install_lariat_to_databases

    func(ns.cloud)


if __name__ == '__main__':
    main()

