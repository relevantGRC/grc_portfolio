"""
S3 Bucket Policy Remediation Lambda Function

This function automatically remediates S3 bucket policy violations by removing public access.
It can be triggered by AWS Config remediation or directly from EventBridge rules.
"""

import json
import boto3
import logging
import os
import datetime

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client("s3")
s3_resource = boto3.resource("s3")
sns_client = boto3.client("sns")

# Get environment variables
# SNS_TOPIC_ARN: ARN of the SNS topic for sending notifications about remediation actions
# EVIDENCE_BUCKET: S3 bucket name for storing remediation evidence and logs
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN", "")
EVIDENCE_BUCKET = os.environ.get("EVIDENCE_BUCKET", "")


def lambda_handler(event, context):
    """
    Main Lambda handler function for remediating S3 bucket policy violations.

    This function determines the type of invocation (AWS Config, EventBridge, or direct)
    and routes the event to the appropriate handler function.

    Args:
        event (dict): The event triggering the Lambda function
        context (object): Lambda context object

    Returns:
        dict: Response containing the remediation status
    """
    logger.info(f"Received event: {json.dumps(event)}")

    # Determine the type of invocation based on the event structure
    if "invokingEvent" in event:
        # This is an AWS Config rule invocation - contains configurationItem
        return handle_config_invocation(event)
    elif "detail" in event and event.get("source") == "aws.s3":
        # This is an EventBridge event for S3 bucket policy changes
        return handle_eventbridge_invocation(event)
    elif "bucket_name" in event:
        # This is a direct invocation with bucket name specified
        bucket_name = event["bucket_name"]
        return remediate_bucket(bucket_name)
    else:
        error_msg = "Unsupported event format"
        logger.error(error_msg)
        return {"statusCode": 400, "body": json.dumps({"error": error_msg})}


def handle_config_invocation(event):
    """
    Handle invocation from AWS Config remediation.

    Extracts the bucket name from the AWS Config event and calls
    the remediation function.

    Args:
        event (dict): The AWS Config event

    Returns:
        dict: Response containing the remediation status
    """
    try:
        # Parse the invoking event from AWS Config
        invoking_event = json.loads(event["invokingEvent"])
        configuration_item = invoking_event["configurationItem"]
        bucket_name = configuration_item["resourceName"]

        logger.info(f"Processing AWS Config remediation for bucket: {bucket_name}")
        return remediate_bucket(bucket_name)
    except Exception as e:
        error_msg = f"Error processing AWS Config event: {str(e)}"
        logger.error(error_msg)
        return {"statusCode": 500, "body": json.dumps({"error": error_msg})}


def handle_eventbridge_invocation(event):
    """
    Handle invocation from EventBridge rule.

    Extracts the bucket name from the EventBridge event and calls
    the remediation function.

    Args:
        event (dict): The EventBridge event

    Returns:
        dict: Response containing the remediation status
    """
    try:
        # Extract bucket name from the EventBridge event detail
        detail = event["detail"]
        bucket_name = detail.get("requestParameters", {}).get("bucketName")

        if not bucket_name:
            error_msg = "Could not determine bucket name from event"
            logger.error(error_msg)
            return {"statusCode": 400, "body": json.dumps({"error": error_msg})}

        logger.info(f"Processing EventBridge event for bucket: {bucket_name}")
        return remediate_bucket(bucket_name)
    except Exception as e:
        error_msg = f"Error processing EventBridge event: {str(e)}"
        logger.error(error_msg)
        return {"statusCode": 500, "body": json.dumps({"error": error_msg})}


def remediate_bucket(bucket_name):
    """
    Remediate S3 bucket by removing public access.

    This function:
    1. Captures the current state of the bucket for evidence
    2. Applies bucket public access block settings
    3. Removes any public statements from the bucket policy
    4. Captures the remediated state
    5. Logs the remediation action
    6. Sends a notification (if configured)

    Args:
        bucket_name (str): The name of the S3 bucket to remediate

    Returns:
        dict: Response containing the remediation status
    """
    try:
        # Capture the current state for evidence and auditing
        current_state = capture_current_state(bucket_name)

        # Apply bucket public access block - this is the primary remediation
        # It blocks public access at the bucket level regardless of ACLs or policies
        logger.info(f"Applying public access block to bucket: {bucket_name}")
        s3_client.put_public_access_block(
            Bucket=bucket_name,
            PublicAccessBlockConfiguration={
                "BlockPublicAcls": True,  # Block new public ACLs and uploads with public ACLs
                "IgnorePublicAcls": True,  # Ignore existing public ACLs
                "BlockPublicPolicy": True,  # Block new public bucket policies
                "RestrictPublicBuckets": True,  # Restrict access to buckets with public policies
            },
        )

        # Check if bucket has a policy and remediate if needed
        try:
            policy = s3_client.get_bucket_policy(Bucket=bucket_name)
            policy_json = json.loads(policy["Policy"])

            # Check if policy allows public access and remove those statements
            modified = False
            if "Statement" in policy_json:
                original_statements = policy_json["Statement"]
                filtered_statements = []

                # Iterate through each statement and filter out public ones
                for statement in original_statements:
                    # Check if statement allows public access
                    if is_public_statement(statement):
                        logger.info(
                            f"Removing public statement from bucket policy: {json.dumps(statement)}"
                        )
                        modified = True
                    else:
                        filtered_statements.append(statement)

                if modified:
                    if filtered_statements:
                        # Update policy with non-public statements
                        policy_json["Statement"] = filtered_statements
                        logger.info(
                            f"Updating bucket policy with {len(filtered_statements)} non-public statements"
                        )
                        s3_client.put_bucket_policy(
                            Bucket=bucket_name, Policy=json.dumps(policy_json)
                        )
                    else:
                        # If no statements left, delete the policy entirely
                        logger.info(
                            f"Deleting bucket policy as all statements were public"
                        )
                        s3_client.delete_bucket_policy(Bucket=bucket_name)

        except s3_client.exceptions.NoSuchBucketPolicy:
            logger.info(f"Bucket {bucket_name} does not have a policy")

        # Capture the remediated state for comparison and evidence
        remediated_state = capture_current_state(bucket_name)

        # Log the remediation action for audit purposes
        log_remediation(bucket_name, current_state, remediated_state)

        # Send notification about the remediation action
        if SNS_TOPIC_ARN:
            send_notification(bucket_name, current_state, remediated_state)

        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "message": f"Successfully remediated bucket: {bucket_name}",
                    "bucket_name": bucket_name,
                }
            ),
        }
    except Exception as e:
        error_msg = f"Error remediating bucket {bucket_name}: {str(e)}"
        logger.error(error_msg)
        return {
            "statusCode": 500,
            "body": json.dumps({"error": error_msg, "bucket_name": bucket_name}),
        }


def is_public_statement(statement):
    """
    Check if a policy statement allows public access.

    A statement is considered public if:
    1. It has an Effect of "Allow" AND
    2. The Principal is "*" or {"AWS": "*"} (indicating anyone) AND
    3. There are no restrictive conditions

    Args:
        statement (dict): The policy statement to check

    Returns:
        bool: True if the statement allows public access, False otherwise
    """
    # Check if the statement has an Effect of "Allow"
    if statement.get("Effect") != "Allow":
        return False

    # Check Principal for public access indicators
    # Principal can be a string "*" or a dict with "AWS": "*"
    principal = statement.get("Principal", {})
    if principal == "*":
        return True
    elif isinstance(principal, dict) and principal.get("AWS") == "*":
        return True

    # Check for public access in conditions
    # If there are no conditions and the principal is public, then it's a public statement
    condition = statement.get("Condition", {})
    if not condition:
        # If Principal indicates public access and there's no condition, it's public
        if principal == "*" or (
            isinstance(principal, dict) and principal.get("AWS") == "*"
        ):
            return True

    return False


def capture_current_state(bucket_name):
    """
    Capture the current state of the bucket for evidence.

    This function collects:
    1. Public access block configuration
    2. Bucket policy
    3. Bucket ACL

    This information is used for auditing, comparison, and potential rollback.

    Args:
        bucket_name (str): The name of the S3 bucket

    Returns:
        dict: The current state of the bucket
    """
    state = {
        "timestamp": datetime.datetime.now().isoformat(),
        "bucket_name": bucket_name,
        "public_access_block": None,
        "bucket_policy": None,
        "bucket_acl": None,
    }

    # Get public access block configuration
    try:
        public_access_block = s3_client.get_public_access_block(Bucket=bucket_name)
        state["public_access_block"] = public_access_block[
            "PublicAccessBlockConfiguration"
        ]
    except Exception as e:
        logger.warning(f"Could not get public access block for {bucket_name}: {str(e)}")

    # Get bucket policy
    try:
        policy = s3_client.get_bucket_policy(Bucket=bucket_name)
        state["bucket_policy"] = json.loads(policy["Policy"])
    except s3_client.exceptions.NoSuchBucketPolicy:
        logger.info(f"Bucket {bucket_name} does not have a policy")
    except Exception as e:
        logger.warning(f"Could not get bucket policy for {bucket_name}: {str(e)}")

    # Get bucket ACL
    try:
        acl = s3_client.get_bucket_acl(Bucket=bucket_name)
        state["bucket_acl"] = acl
    except Exception as e:
        logger.warning(f"Could not get bucket ACL for {bucket_name}: {str(e)}")

    return state


def log_remediation(bucket_name, original_state, remediated_state):
    """
    Log the remediation action to the evidence bucket.

    This function creates a detailed record of the remediation action,
    including the original and remediated states, and stores it in the
    evidence bucket for audit purposes.

    Args:
        bucket_name (str): The name of the S3 bucket
        original_state (dict): The state of the bucket before remediation
        remediated_state (dict): The state of the bucket after remediation
    """
    if not EVIDENCE_BUCKET:
        logger.warning("No evidence bucket specified, skipping evidence collection")
        return

    try:
        # Create a comprehensive evidence record
        evidence = {
            "remediation_type": "S3 Bucket Public Access Removal",
            "timestamp": datetime.datetime.now().isoformat(),
            "bucket_name": bucket_name,
            "original_state": original_state,
            "remediated_state": remediated_state,
            "was_public": is_policy_public(original_state.get("bucket_policy")),
            "is_public": is_policy_public(remediated_state.get("bucket_policy")),
        }

        # Create a unique key for the evidence file
        evidence_key = f"remediation-logs/s3-buckets/{bucket_name}/{datetime.datetime.now().strftime('%Y-%m-%d-%H-%M-%S')}.json"

        # Upload the evidence to S3 with encryption
        s3_client.put_object(
            Bucket=EVIDENCE_BUCKET,
            Key=evidence_key,
            Body=json.dumps(evidence, default=str),
            ContentType="application/json",
            ServerSideEncryption="AES256",
        )

        logger.info(
            f"Remediation evidence saved to s3://{EVIDENCE_BUCKET}/{evidence_key}"
        )
    except Exception as e:
        logger.error(f"Error saving remediation evidence: {str(e)}")


def send_notification(bucket_name, original_state, remediated_state):
    """
    Send a notification about the remediation action.

    This function creates a human-readable message about the remediation
    action and sends it via SNS to notify stakeholders.

    Args:
        bucket_name (str): The name of the S3 bucket
        original_state (dict): The state of the bucket before remediation
        remediated_state (dict): The state of the bucket after remediation
    """
    try:
        # Format a human-readable message for the notification
        message = f"""
SECURITY ALERT: S3 Bucket Public Access Remediation

Bucket Name: {bucket_name}
Timestamp: {datetime.datetime.now().isoformat()}

Remediation Actions:
- Public Access Block: {'Applied' if remediated_state.get('public_access_block') else 'Not Applied'}
- Public Policy Statements: {'Removed' if is_policy_public(original_state.get('bucket_policy')) and not is_policy_public(remediated_state.get('bucket_policy')) else 'None Found'}

This bucket had public access settings that have been automatically remediated.
Please review the bucket configuration to ensure it meets your security requirements.

This is an automated message from the S3 Bucket Policy Remediation function.
        """

        # Send the notification
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=f"S3 Bucket Remediated: {bucket_name}",
            Message=message,
        )

        logger.info(f"Notification sent to {SNS_TOPIC_ARN}")
    except Exception as e:
        logger.error(f"Error sending notification: {str(e)}")


def is_policy_public(policy):
    """
    Check if a bucket policy contains any public statements.

    Args:
        policy (dict): The bucket policy to check

    Returns:
        bool: True if the policy contains public statements, False otherwise
    """
    if not policy:
        return False

    # Check each statement in the policy
    for statement in policy.get("Statement", []):
        if is_public_statement(statement):
            return True

    return False
