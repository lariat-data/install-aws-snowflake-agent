### Intro

This repository contains the Docker image and dependencies for the Lariat agent installer for Snowflake on AWS

### How it works
This installer uses Terraform, with remote `.tfstate` files, to create and manage infrastructure in the target cloud account and data source.

This installer creates:
- A Snowflake user account, and warehouse for monitoring target Snowflake databases
- Snowflake UDFs for functions used by the agent such as HyperLogLog Counts.
- An AWS Lambda Function for running scheduled monitoring queries
- An S3 bucket for storing YAML configuration
- IAM Users, Roles and Policies to support the above operations.

### Structure
- The Entrypoint for Lariat installations is [init-and-apply.sh](init-and-apply.sh). This script contacts Lariat for the latest Terraform state (which may be empty), and proceeds to work against this state.

- Snowflake infrastructure-as-code definitions live under [snowflake.tf](snowflake.tf)

- AWS infrastructure-as-code definitions live under [modules/aws/main.tf](modules/aws/main.tf)

### Building locally
You may build and run a local version of this image using `docker`.

```docker
docker build -t <my_image_name> .
```
