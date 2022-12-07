import argparse
import sys
import os
import json
import subprocess
import snowflake.connector
from ruamel.yaml import YAML

SNOWFLAKE_WAREHOUSE = os.getenv("SNOWFLAKE_WAREHOUSE")
SNOWFLAKE_ACCOUNT_LOCATOR = os.getenv(
    "SNOWFLAKE_ACCOUNT_LOCATOR"
)
SNOWFLAKE_REGION = os.getenv("SNOWFLAKE_REGION")
SNOWFLAKE_ACCOUNT = os.getenv("SNOWFLAKE_ACCOUNT")
SNOWFLAKE_USER = os.getenv("SNOWFLAKE_USER")
SNOWFLAKE_PASSWORD = os.environ["SNOWFLAKE_PASSWORD"]

LARIAT_API_KEY = os.getenv("LARIAT_API_KEY")
LARIAT_APPLICATION_KEY = os.getenv("LARIAT_APPLICATION_KEY")
S3_QUERY_RESULTS_BUCKET = "lariat-snowflak-default-query-results"
S3_AGENT_CONFIG_BUCKET = "lariat-snowflake-default-config"
QUERY_DISPATCH_INTERVAL_CRON = "cron(48 * * * ? *)"

AWS_REGION = os.getenv("AWS_REGION")
AZURE_REGION = os.getenv("AZURE_REGION")

YAML_LOCATION = "config/snowflake_agent.yaml"

def validate_agent_config(cloud):
    yaml = YAML(typ="safe")

    with open(YAML_LOCATION) as agent_config_file:
        agent_config = yaml.load(agent_config_file)

    assert "source_id" in agent_config
    assert "databases" in agent_config
    assert isinstance(agent_config["databases"], dict)

    for db in agent_config["databases"].keys():
        assert isinstance(agent_config["databases"][db], dict)

        for schema_name in agent_config["databases"][db].keys():
            assert isinstance(agent_config["databases"][db][schema_name], list)

    print(f"Agent Config Validated: \n {json.dumps(agent_config, indent=4)}")

def get_target_snowflake_databases():
    yaml = YAML(typ="safe")

    with open(YAML_LOCATION) as agent_config_file:
        agent_config = yaml.load(agent_config_file)

    return list(agent_config["databases"].keys())


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
    validate_agent_config(cloud)

    dbs = get_snowflake_databases()
    filtered_dbs = [db for db in dbs if db.upper() in get_target_snowflake_databases()]
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
        "TF_VAR_snowflake_databases": f"{json.dumps(filtered_dbs)}",
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
    for k, v in tf_env.items():
        my_env[k] = v

    subprocess.run(["terraform", "apply"], env=my_env)


def destroy_lariat_installations(cloud="aws"):
    validate_agent_config(cloud)

    dbs = get_snowflake_databases()
    filtered_dbs = [db for db in dbs if db.upper() in get_target_snowflake_databases()]
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
        "TF_VAR_snowflake_databases": f"{json.dumps(filtered_dbs)}",
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
    for k, v in tf_env.items():
        my_env[k] = v

    subprocess.run(["terraform", "destroy"], env=my_env)


def plan_lariat_installation(cloud="aws"):
    validate_agent_config(cloud)

    dbs = get_snowflake_databases()
    filtered_dbs = [db for db in dbs if db.upper() in get_target_snowflake_databases()]
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
        "TF_VAR_snowflake_databases": f"{json.dumps(filtered_dbs)}",
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
    for k, v in tf_env.items():
        my_env[k] = v

    subprocess.run(["terraform", "plan"], env=my_env)


def main():
    parser = argparse.ArgumentParser(
        description="Manage a Lariat Snowflake Installation"
    )
    parser.add_argument(
        "--action", choices=["plan", "apply", "destroy", "validate_config"]
    )
    parser.add_argument("--cloud", choices=["aws", "azure"])
    ns = parser.parse_args(sys.argv[1:])

    if ns.action == "destroy":
        func = destroy_lariat_installations
    elif ns.action == "plan":
        func = plan_lariat_installation
    elif ns.action == "apply":
        func = install_lariat_to_databases
    elif ns.action == "validate_config":
        func = validate_agent_config

    func(ns.cloud)


if __name__ == "__main__":
    main()
