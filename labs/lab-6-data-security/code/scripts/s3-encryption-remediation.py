"""
S3 Encryption Remediation Lambda Function

This function automatically remediates S3 objects that are not properly encrypted.
It can be triggered by EventBridge rules when objects are uploaded without encryption.
"""

import json
import logging
import os

import boto3
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client("s3")
sns_client = boto3.client("sns")

# Get environment variables
KMS_KEY_ID = os.environ.get("KMS_KEY_ID", "")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN", "")


def lambda_handler(event, context):
    """
    Main Lambda handler function for remediating unencrypted S3 objects.

    This function checks if S3 objects are properly encrypted with the specified
    KMS key and remediates them if they are not.

    Args:
        event (dict): The event triggering the Lambda function
        context (object): Lambda context object

    Returns:
        dict: Response containing the remediation status
    """
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        # Extract bucket and object information from the event
        if "detail" in event and "requestParameters" in event["detail"]:
            # This is an EventBridge event
            bucket_name = event["detail"]["requestParameters"]["bucketName"]
            object_key = event["detail"]["requestParameters"]["key"]
        elif (
            "Records" in event
            and len(event["Records"]) > 0
            and "s3" in event["Records"][0]
        ):
            # This is an S3 event notification
            bucket_name = event["Records"][0]["s3"]["bucket"]["name"]
            object_key = event["Records"][0]["s3"]["object"]["key"]
        else:
            # Direct invocation with parameters
            bucket_name = event.get("bucket_name")
            object_key = event.get("object_key")

            if not bucket_name or not object_key:
                error_msg = "Could not determine bucket name and object key from event"
                logger.error(error_msg)
                return {"statusCode": 400, "body": json.dumps({"error": error_msg})}

        # Check if the object is properly encrypted
        encryption_status = check_encryption(bucket_name, object_key)

        if not encryption_status["is_encrypted"] or (
            KMS_KEY_ID and encryption_status["kms_key_id"] != KMS_KEY_ID
        ):
            # Object is not encrypted or not encrypted with the correct key
            logger.info(
                f"Object {object_key} in bucket {bucket_name} is not properly encrypted. Remediating..."
            )

            # Remediate the object
            remediate_object(bucket_name, object_key)

            # Send notification
            if SNS_TOPIC_ARN:
                send_notification(bucket_name, object_key, encryption_status)

            return {
                "statusCode": 200,
                "body": json.dumps(
                    {
                        "message": f"Successfully remediated encryption for {object_key} in bucket {bucket_name}",
                        "bucket_name": bucket_name,
                        "object_key": object_key,
                    }
                ),
            }
        else:
            # Object is already properly encrypted
            logger.info(
                f"Object {object_key} in bucket {bucket_name} is already properly encrypted"
            )
            return {
                "statusCode": 200,
                "body": json.dumps(
                    {
                        "message": f"No remediation needed for {object_key} in bucket {bucket_name}",
                        "bucket_name": bucket_name,
                        "object_key": object_key,
                    }
                ),
            }
    except Exception as e:
        error_msg = f"Error processing event: {str(e)}"
        logger.error(error_msg)
        return {"statusCode": 500, "body": json.dumps({"error": error_msg})}


def check_encryption(bucket_name, object_key):
    """
    Check if an S3 object is properly encrypted.

    Args:
        bucket_name (str): The name of the S3 bucket
        object_key (str): The key of the S3 object

    Returns:
        dict: Dictionary containing encryption status information
    """
    try:
        # Get the object's metadata
        response = s3_client.head_object(Bucket=bucket_name, Key=object_key)

        # Check if the object is encrypted
        is_encrypted = "ServerSideEncryption" in response
        encryption_type = response.get("ServerSideEncryption", "None")
        kms_key_id = response.get("SSEKMSKeyId", "")

        return {
            "is_encrypted": is_encrypted,
            "encryption_type": encryption_type,
            "kms_key_id": kms_key_id,
        }
    except ClientError as e:
        logger.error(
            f"Error checking encryption for {object_key} in bucket {bucket_name}: {str(e)}"
        )
        raise


def remediate_object(bucket_name, object_key):
    """
    Remediate an unencrypted S3 object by copying it with encryption.

    Args:
        bucket_name (str): The name of the S3 bucket
        object_key (str): The key of the S3 object
    """
    try:
        # Copy the object back to itself with proper encryption
        copy_source = {"Bucket": bucket_name, "Key": object_key}

        encryption_args = {"ServerSideEncryption": "aws:kms"}

        if KMS_KEY_ID:
            encryption_args["SSEKMSKeyId"] = KMS_KEY_ID

        s3_client.copy_object(
            Bucket=bucket_name,
            Key=object_key,
            CopySource=copy_source,
            **encryption_args,
        )

        logger.info(
            f"Successfully remediated encryption for {object_key} in bucket {bucket_name}"
        )
    except ClientError as e:
        logger.error(
            f"Error remediating encryption for {object_key} in bucket {bucket_name}: {str(e)}"
        )
        raise


def send_notification(bucket_name, object_key, encryption_status):
    """
    Send a notification about the remediation action.

    Args:
        bucket_name (str): The name of the S3 bucket
        object_key (str): The key of the S3 object
        encryption_status (dict): The original encryption status
    """
    try:
        # Format the notification message
        message = f"""
SECURITY ALERT: S3 Object Encryption Remediation

An S3 object was uploaded without proper encryption and has been automatically remediated.

Bucket: {bucket_name}
Object: {object_key}
Original Encryption: {encryption_status['encryption_type']}
Original KMS Key: {encryption_status['kms_key_id'] or 'None'}

The object has been re-encrypted with KMS key: {KMS_KEY_ID or 'Default KMS Key'}

This is an automated message from the S3 Encryption Remediation function.
        """

        # Send the notification
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=f"S3 Object Encryption Remediated: {bucket_name}/{object_key}",
            Message=message,
        )

        logger.info(f"Notification sent to {SNS_TOPIC_ARN}")
    except ClientError as e:
        logger.error(f"Error sending notification: {str(e)}")
        # Don't raise the exception, as this is not critical to the remediation
