import boto3

def encrypt_and_copy_keypair(LARIAT_PROFILE, LARIAT_TEST_CUSTOMER_KEY_ID, LARIAT_TF_VARS_FILE, LARIAT_TF_VARS_ENC_FILE, LARIAT_CUSTOMER_ACCOUNT_ID, LARIAT_CROSS_ACCOUNTROLE_ARN, LARIAT_CROSS_ACCOUNTROLE_SESSION_NAME, LARIAT_TERRAFORM_BUCKET_NAME):

    # Open session from Lariat profile (assuming lariat)
    session = boto3.Session(profile_name=LARIAT_PROFILE)
    s3_client = session.client('s3')

    # Define the AWS KMS client
    kms_client = session.client('kms')

    # Encrypt the credentiasl file from Lariat account
    with open(LARIAT_TF_VARS_FILE, "rb") as plaintext_file:
        plaintext = plaintext_file.read()

        response = kms_client.encrypt(
            KeyId=LARIAT_TEST_CUSTOMER_KEY_ID,
            Plaintext=plaintext,
            EncryptionContext={'user': 'terraform-user-' + LARIAT_CUSTOMER_ACCOUNT_ID}
        )
        encrypted_text = response['CiphertextBlob']
        with open(LARIAT_TF_VARS_ENC_FILE, "wb") as encrypted_file:
            encrypted_file.write(encrypted_text)


    # Create a client for the STS service in Lariat AWS
    sts_client = session.client('sts')

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

    # Upload the file to the specified S3 bucket and folder location
    with open(LARIAT_TF_VARS_ENC_FILE, "rb") as data:
        s3_client.upload_fileobj(
            data,
            LARIAT_TERRAFORM_BUCKET_NAME,
            f"{LARIAT_CUSTOMER_ACCOUNT_ID}/testkeys/{LARIAT_TF_VARS_ENC_FILE}"
        )
    
    return f"s3://{LARIAT_TERRAFORM_BUCKET_NAME}/{LARIAT_CUSTOMER_ACCOUNT_ID}/testkeys/{LARIAT_TF_VARS_ENC_FILE}"

#print(encrypt_and_copy_keypair("lariattemp","arn:aws:kms:us-east-2:358681817243:key/c16a7427-3e82-4a53-aad9-885acd3806b2", "terraform.tfvars", "terraform.tfvars.enc", "553600746148", "arn:aws:iam::358681817243:role/milorad-test-cross-acount-role", "lariat-terraform-s3-session", "lariat-customer-installation-tfstate"))