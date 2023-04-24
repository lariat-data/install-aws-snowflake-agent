## Intro

[Lariat Data](www.lariatdata.com) is a Continuous Data Quality Monitoring Platform to ensure data products don't break even as business logic, input data and infrastructure change.

This repository contains the Docker image and dependencies for installing the Lariat Snowflake Agent on AWS.

## How it works
This installer uses Terraform, with remote `.tfstate` files, to create and manage infrastructure in the target cloud account and data source.

This installer creates:
- A Snowflake user account, and warehouse for monitoring the target Snowflake databases
- Snowflake UDFs for functions used by the agent such as HyperLogLog Counts.
- An AWS Lambda Function for running scheduled monitoring queries
- An S3 bucket for storing YAML configuration
- IAM Users, Roles and Policies to support the above operations.

## Structure
- The Entrypoint for Lariat installations is [init-and-apply.sh](init-and-apply.sh). This script contacts Lariat for the latest Terraform state (which may be empty), and proceeds to work against this state.

- Snowflake infrastructure-as-code definitions live under [snowflake.tf](snowflake.tf)

- AWS infrastructure-as-code definitions live under [modules/aws/main.tf](modules/aws/main.tf)

## Configuration
This image requires the following configuration values to be injected as environment variables:
- `AWS_REGION` - The target AWS region for the installation. Generally, this should be the same AWS region where Snowflake is deployed. e.g. `us-east-1`
- `AWS_ACCOUNT_ID` - A 12-digit AWS Account Identifier
- `LARIAT_API_KEY` - A Lariat API Key. You can retrieve this from the [`API Keys`](https://app.lariatdata.com/user/keys) page in your Lariat account
- `LARIAT_APPLICATION_KEY` - A Lariat Application Key. You can retrieve this from the [`API Keys`](https://app.lariatdata.com/user/keys) page in your Lariat account

Additionally this image requires a valid YAML configuration file for Snowflake to be mounted at `/workspace/snowflake_agent.yaml`. Read more about this configuration file [here](https://docs.lariatdata.com/fundamentals/configuration/configuring-the-snowflake-agent)

## Building locally
You may build and run a local version of this image using `docker`.

```docker
docker build -t <my_image_name> .
```

## Running locally

### Install the agent
The required configuration values may be passed in during `docker run`, for example:

```docker
docker run -it \
--mount type=bind,source=/path/to/my/snowflake_agent.yaml,target=/workspace/snowflake_agent.yaml,readonly \
-e AWS_REGION=<my_aws_region> \
-e AWS_ACCOUNT_ID=<aws_account_id> \
-e LARIAT_API_KEY=<lariat_api_key> \
-e LARIAT_APPLICATION_KEY=<lariat_application_key> \
lariatdata/install-aws-snowflake-agent:latest
```

### Uninstall the agent
The required configuration values may be passed in during `docker run`, for example:

```docker
docker run -it \
--mount type=bind,source=/path/to/my/snowflake_agent.yaml,target=/workspace/snowflake_agent.yaml,readonly \
-e AWS_REGION=<my_aws_region> \
-e AWS_ACCOUNT_ID=<aws_account_id> \
-e LARIAT_API_KEY=<lariat_api_key> \
-e LARIAT_APPLICATION_KEY=<lariat_application_key> \
lariatdata/install-aws-snowflake-agent:latest uninstall
```
