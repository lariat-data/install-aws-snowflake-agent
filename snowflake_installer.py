from prompt_toolkit import prompt, PromptSession
from prompt_toolkit.completion import WordCompleter

from snowflake.connector import connect
from collections import defaultdict
from ruamel.yaml import YAML

import json
import os
import sys
import subprocess

def validate_agent_config():
    yaml = YAML()

    with open("snowflake_agent.yaml") as agent_config_file:
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
    yaml = YAML()

    with open("snowflake_agent.yaml") as agent_config_file:
        agent_config = yaml.load(agent_config_file)

    return list(agent_config["databases"].keys())

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

def prompt_for_config(session):
    new_line = '\n'
    dbs = get_snowflake_databases(snowflake_user, snowflake_account, snowflake_pwd)
    filtered_dbs = session.prompt(f"\nWe've detected the following databases in your Snowflake instance \n{new_line.join(dbs)}\n\nPlease input the databases you'd like to monitor with Lariat as a comma-separated list e.g. db1,db2:\n", is_password=False, completer=WordCompleter(dbs))
    db_to_schema = {}

    for db in filtered_dbs.split(","):
        schemas = get_snowflake_schemas(snowflake_user, snowflake_account, snowflake_pwd, db)
        filtered_schemas = session.prompt(f"\nWe've detected the following schemas in your Snowflake database {db} \n{new_line.join(schemas)}\n\nPlease input the schemas you'd like to monitor with Lariat as a comma-separated list e.g. schema1,schema2:\n", is_password=False, completer=WordCompleter(schemas))

        db_to_schema[db] = filtered_schemas.split(",")

    db_schema_to_tables = defaultdict(dict)
    for db, schemas in db_to_schema.items():
        for schema in schemas:
            tables = get_snowflake_tables(snowflake_user, snowflake_account, snowflake_pwd, db, schema)
            filtered_tables = session.prompt(f"\nWe've detected the following tables in schema {schema} of database {db} \n{new_line.join(tables)}\n\nPlease input the tables you'd like to monitor with Lariat as a comma-separated list e.g. table1,table2:\n", is_password=False, completer=WordCompleter(tables))
            db_schema_to_tables[db][schema] = filtered_tables.split(",")

    yaml = YAML()

    snowflake_config = {"databases": dict(db_schema_to_tables), "source_id": source_id}
    print("Saving your snowflake agent config")
    yaml.dump(snowflake_config, sys.stdout)

    with open("config/snowflake_agent.yaml", "wb") as f:
        yaml.dump(snowflake_config, f)

if __name__ == '__main__':
    session = PromptSession()
    snowflake_account = session.prompt("Snowflake Account identifier: ")
    snowflake_user = session.prompt("Snowflake Username: ")
    snowflake_pwd = session.prompt(f'Enter the password for Snowflake user {snowflake_user}: ', is_password=True)

    dbs = get_snowflake_databases(snowflake_user, snowflake_account, snowflake_pwd)
    filtered_dbs = [db for db in dbs if db.upper() in get_target_snowflake_databases()]
    if not filtered_dbs:
        print("No valid database found for Lariat installation")
        sys.exit(1)

    validate_agent_config()
    print(f"Installing lariat to Snowflake Databases {filtered_dbs}")

    snowflake_default_wh = prompt('Enter a default warehouse to run Lariat installation commands (e.g. COMPUTE_WH): ')

    lariat_api_key = os.environ.get("LARIAT_API_KEY")
    lariat_application_key = os.environ.get("LARIAT_APPLICATION_KEY")
    aws_region = os.environ.get("AWS_REGION")

    lariat_sink_aws_access_key_id = os.getenv("LARIAT_TMP_AWS_ACCESS_KEY_ID")
    lariat_sink_aws_secret_access_key = os.getenv("LARIAT_TMP_AWS_SECRET_ACCESS_KEY")

    tf_env = {
        "snowflake_default_warehouse": snowflake_default_wh,
        "snowflake_user": snowflake_user,
        "snowflake_password": snowflake_pwd,
        "snowflake_databases": filtered_dbs,
        "snowflake_account": snowflake_account,
        "lariat_api_key": lariat_api_key,
        "lariat_application_key": lariat_application_key,
        "lariat_sink_aws_access_key_id": lariat_sink_aws_access_key_id,
        "lariat_sink_aws_secret_access_key": lariat_sink_aws_secret_access_key,
        "aws_region": aws_region,
    }

    print("Passing configuration through to terraform")
    with open("lariat.auto.tfvars.json", "w") as f:
        json.dump(tf_env, f)
