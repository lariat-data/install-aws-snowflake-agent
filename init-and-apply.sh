#!/bin/sh

# Get a local AWS profile for interacting with remote tfstate stored with Lariat
echo "Storing local lariat profile..."
python3 scripts/kms/decrypt_and_store_remote_tfstate_profile.py ${AWS_ACCOUNT_ID} > lariat_profile.json

cat lariat_profile.json | jq -r .AccessKeyId | xargs aws configure set aws_access_key_id $1 --profile lariat
cat lariat_profile.json | jq -r .SecretAccessKey | xargs aws configure set aws_secret_access_key $1 --profile lariat
cat lariat_profile.json | jq -r .SessionToken | xargs aws configure set aws_session_token $1 --profile lariat

echo "Initializing Terraform..."
terraform init -reconfigure \
              -backend-config="key=${AWS_ACCOUNT_ID}/snowflake/terraform.tfstate" \
              -backend-config="bucket=lariat-customer-installation-tfstate" \
              -backend-config="region=us-east-2" \
	      -backend-config="access_key=$(aws configure get aws_access_key_id --profile lariat)" \
	      -backend-config="secret_key=$(aws configure get aws_secret_access_key --profile lariat)" \
	      -backend-config="token=$(aws configure get aws_session_token --profile lariat)"

python3 snowflake_installer.py

terraform apply -auto-approve
