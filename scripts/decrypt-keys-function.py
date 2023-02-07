import boto3

def get_and_decrypt_keypair(LARIAT_CUSTOMER_PROFILE, LARIAT_TF_VARS_FILE, LARIAT_TF_VARS_ENC_FILE, LARIAT_CUSTOMER_ACCOUNT_ID, LARIAT_TERRAFORM_BUCKET_NAME):

    # Open session from customer's profile (assuming default)
    session = boto3.Session(profile_name=LARIAT_CUSTOMER_PROFILE)
    s3_client = session.client('s3')
    s3_client.download_file(LARIAT_TERRAFORM_BUCKET_NAME, f"{LARIAT_CUSTOMER_ACCOUNT_ID}/testkeys/{LARIAT_TF_VARS_ENC_FILE}", LARIAT_TF_VARS_ENC_FILE)

    # Define the AWS KMS client
    kms_client = session.client('kms')

    # Decrypt the credentials file from Lariat account
    with open(LARIAT_TF_VARS_ENC_FILE, "rb") as encrypted_file:
        encrypted_text = encrypted_file.read()
        response = kms_client.decrypt(
            CiphertextBlob=encrypted_text,
            EncryptionContext={'user': 'terraform-user-' + LARIAT_CUSTOMER_ACCOUNT_ID}
        )
        decrypted_text = response['Plaintext']
        with open(LARIAT_TF_VARS_FILE, "wb") as decrypted_file:
            decrypted_file.write(decrypted_text)

    # Display the content of the decrypted file
    with open(LARIAT_TF_VARS_FILE, "r") as file:
            content = file.read().strip()
    return content

# print(get_and_decrypt_keypair("default", "terraform.tfvars", "terraform.tfvars.enc", "553600746148", "lariat-customer-installation-tfstate"))