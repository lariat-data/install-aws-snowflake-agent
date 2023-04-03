from prompt_toolkit import prompt, PromptSession
from snowflake.connector import connect
from collections import defaultdict
from ruamel.yaml import YAML

import json
import os
import sys
import subprocess

def get_snowflake_databases(username, account, pwd):
    print("Attempting to list snowflake databases")
    con = connect(
        user=username,
        account=account,
        password=pwd,
        role="ACCOUNTADMIN",
    )

    cur = con.cursor()
    result = cur.execute("SHOW DATABASES")
    databases = [r[1] for r in result]

    return databases


def get_snowflake_schemas(username, account, pwd, db):
    con = connect(
        user=username,
        account=account,
        password=pwd,
        role="ACCOUNTADMIN",
    )

    cur = con.cursor()
    result = cur.execute(f"SHOW SCHEMAS IN {db}")
    schemas = [r[1] for r in result]

    return schemas

def get_snowflake_tables(username, account, pwd, db, schema):
    con = connect(
        user=username,
        account=account,
        password=pwd,
        role="ACCOUNTADMIN",
    )

    cur = con.cursor()
    result = cur.execute(f"SHOW TABLES IN {db}.{schema}")
    tables = [r[1] for r in result]

    return tables


if __name__ == '__main__':
    session = PromptSession()
    source_id = session.prompt("Enter a unique source ID for this integration (e.g. acmeco_snowflake_us_east_2): ")

    snowflake_account = session.prompt("Snowflake Account identifier: ")
    snowflake_user = session.prompt("Snowflake Username: ")
    snowflake_pwd = session.prompt(f'Enter the password for Snowflake user {snowflake_user}: ', is_password=True)

    dbs = get_snowflake_databases(snowflake_user, snowflake_account, snowflake_pwd)
    filtered_dbs = session.prompt(f"We've detected the following databases in your Snowflake instance \n{','.join(dbs)}\nPlease input the databases you'd like to monitor with Lariat as a comma-separated list e.g. db1,db2: ", is_password=False)
    db_to_schema = {}

    for db in filtered_dbs.split(","):
        schemas = get_snowflake_schemas(snowflake_user, snowflake_account, snowflake_pwd, db)
        filtered_schemas = session.prompt(f"We've detected the following schemas in your Snowflake database {db} \n{','.join(schemas)}\nPlease input the schemas you'd like to monitor with Lariat as a comma-separated list e.g. schema1,schema2: ", is_password=False)

        db_to_schema = {db: filtered_schemas.split(",")}


    db_schema_to_tables = defaultdict(dict)
    for db, schemas in db_to_schema.items():
        for schema in schemas:
            tables = get_snowflake_tables(snowflake_user, snowflake_account, snowflake_pwd, db, schema)
            filtered_tables = session.prompt(f"We've detected the following tables in schema {schema} of database {db} \n{','.join(tables)}\nPlease input the tables you'd like to monitor with Lariat as a comma-separated list e.g. table1,table2: ", is_password=False)
            db_schema_to_tables[db][schema] = filtered_tables.split(",")

    yaml = YAML()

    snowflake_config = {"databases": dict(db_schema_to_tables), "source_id": source_id}
    print("Saving your snowflake agent config")
    yaml.dump(snowflake_config, sys.stdout)

    with open("config/snowflake_agent.yaml", "wb") as f:
        yaml.dump(snowflake_config, f)

    snowflake_default_wh = prompt('Enter a default warehouse to run Lariat installation commands (e.g. COMPUTE_WH): ')
    lariat_api_key = os.environ.get("LARIAT_API_KEY")
    lariat_application_key = os.environ.get("LARIAT_APPLICATION_KEY")
    aws_region = os.environ.get("AWS_REGION")

    account_locator_split = snowflake_account.split(".", 1)
    tf_env = {
        "snowflake_account": account_locator_split[0],
        "snowflake_default_warehouse": snowflake_default_wh,
        "snowflake_user": snowflake_user,
        "snowflake_password": snowflake_pwd,
        "snowflake_databases": filtered_dbs.split(","),
        "snowflake_account_locator": snowflake_account,
        "snowflake_region": account_locator_split[1],
        "lariat_api_key": lariat_api_key,
        "lariat_application_key": lariat_application_key,
        "aws_region": aws_region,
    }

    print("Passing configuration through to terraform")
    with open("lariat.auto.tfvars.json", "w") as f:
        json.dump(tf_env, f)
