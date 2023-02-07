import boto3

def replace_iam_keypair(LARIAT_PROFILE, LARIAT_IAM_USER, LARIAT_IAM_ACCESS_KEY_ID):
    # Open session from Lariat profile (assuming lariat)
    session = boto3.Session(profile_name=LARIAT_PROFILE)
    s3_client = session.client('s3')

    # Create an IAM client
    iam = session.client('iam')

    # Create a new access key
    response = iam.create_access_key(UserName=LARIAT_IAM_USER)
    new_username = response['AccessKey']['AccessKeyId']
    new_secret_access_key = response['AccessKey']['SecretAccessKey']

    # Deactivate the existing access key
    iam.update_access_key(UserName=LARIAT_IAM_USER, AccessKeyId=LARIAT_IAM_ACCESS_KEY_ID, Status="Inactive")

    # Verify the new access key is working
    try:
        iam.get_access_key_last_used(AccessKeyId=new_username)
        print("New key for " + LARIAT_IAM_USER + " is working fine.")
    finally:
        # Delete the old access key
        iam.delete_access_key(UserName=LARIAT_IAM_USER, AccessKeyId=LARIAT_IAM_ACCESS_KEY_ID)

# replace_iam_keypair("lariattemp", "terraform-user-553600746148", "XXXXXXXXXXXXXXXXXXX")