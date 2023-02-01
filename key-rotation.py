"""
The script is called by passing these arguments:
AWS_PROFILE=lariat ACCOUNT_ID=358681817243 APP=snowflake python key-rotation.py

At the moment trusted entity for cross account IAM role is delegated to arn:aws:iam::358681817243:user/milorad, which should be changed.
Its security credentials correspond to the AWS Profile named lariat in the example above.
"""

import boto3
import os

LARIAT_CROSS_ACCOUNTROLE_ARN = "arn:aws:iam::358681817243:role/milorad-test-cross-acount-role"
LARIAT_CROSS_ACCOUNTROLE_SESSION_NAME = "lariat-terraform-s3-session"
LARIAT_TERRAFORM_BUCKET_NAME = "lariat-customer-installation-tfstate"
TERRAFORM_SOURCE_FILE = "terraform.tfstate"
LARIAT_ACCOUNT_ID = os.environ["ACCOUNT_ID"] # i.e. 358681817243
LARIAT_SYSTEM_COMPONENT=os.environ["APP"] # i.e "snowflake", "athena"

# Create a client for the STS service in Lariat AWS
sts_client = boto3.client('sts')

# Assume the cross account role 
assumed_role = sts_client.assume_role(
    RoleArn=LARIAT_CROSS_ACCOUNTROLE_ARN,
    RoleSessionName=LARIAT_CROSS_ACCOUNTROLE_SESSION_NAME
)

# Extract the temporary credentials from the assumed role
temp_creds = assumed_role['Credentials']

# Use the temporary credentials to access terraform remote state S3 bucket
s3_client = boto3.client(
    's3',
    aws_access_key_id=temp_creds['AccessKeyId'],
    aws_secret_access_key=temp_creds['SecretAccessKey'],
    aws_session_token=temp_creds['SessionToken']
)

# List Remote Terraform State S3 bucket
#response = s3_client.list_objects(Bucket=LARIAT_TERRAFORM_BUCKET_NAME)

# Extract the contents of the S3 bucket
#contents = response.get('Contents')

# Iterate over the contents of the S3 bucket
#for content in contents:
#    print(content.get('Key'))

# Upload the file to the specified S3 bucket and folder location
with open(TERRAFORM_SOURCE_FILE, "rb") as data:
    s3_client.upload_fileobj(
        data,
        LARIAT_TERRAFORM_BUCKET_NAME,
        f"{LARIAT_ACCOUNT_ID}/{LARIAT_SYSTEM_COMPONENT}/{TERRAFORM_SOURCE_FILE}"
    )