"""
Lambda function for automated encryption compliance remediation.

This function automatically enables encryption for AWS resources that should be encrypted
but are not. It supports remediation for:
1. EBS volumes (enabling encryption)
2. S3 buckets (enabling default encryption)
3. RDS instances (enabling storage encryption)

The function can be triggered by:
1. AWS Config remediation
2. EventBridge rules
3. Direct invocation

For each resource type, the function:
1. Identifies if encryption is missing
2. Applies the appropriate remediation
3. Logs the remediation action
4. Sends a notification (if configured)
"""

import json
import boto3
import logging
import os
import datetime
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client("s3")
ec2_client = boto3.client("ec2")
rds_client = boto3.client("rds")
sns_client = boto3.client("sns")

# Get environment variables
# SNS_TOPIC_ARN: ARN of the SNS topic for sending notifications about remediation actions
# EVIDENCE_BUCKET: S3 bucket name for storing remediation evidence and logs
# KMS_KEY_ID: Optional KMS key ID to use for encryption (if not provided, AWS managed keys are used)
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN", "")
EVIDENCE_BUCKET = os.environ.get("EVIDENCE_BUCKET", "")
KMS_KEY_ID = os.environ.get("KMS_KEY_ID", "")  # Optional KMS key for encryption


def lambda_handler(event, context):
    """
    Main handler function for the Lambda.

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
    if "invokingEvent" in event and "configurationItem" in json.loads(
        event["invokingEvent"]
    ):
        # AWS Config remediation - event contains configurationItem from AWS Config
        return handle_config_invocation(event)
    elif "detail" in event and "resourceType" in event.get("detail", {}):
        # EventBridge rule - event contains detail with resourceType
        return handle_eventbridge_invocation(event)
    else:
        # Direct invocation - event should contain resourceType and resourceId
        resource_type = event.get("resourceType", "")
        resource_id = event.get("resourceId", "")

        if not resource_type or not resource_id:
            return {
                "statusCode": 400,
                "body": "Missing required parameters: resourceType and resourceId",
            }

        return remediate_resource(resource_type, resource_id)


def handle_config_invocation(event):
    """
    Handle invocation from AWS Config remediation.

    Extracts resource information from the AWS Config event and
    calls the remediation function.

    Args:
        event (dict): The AWS Config event

    Returns:
        dict: Response containing the remediation status
    """
    # Parse the invoking event from AWS Config
    invoking_event = json.loads(event["invokingEvent"])
    configuration_item = invoking_event["configurationItem"]

    # Extract resource information
    resource_type = configuration_item["resourceType"]
    resource_id = configuration_item["resourceId"]

    logger.info(f"AWS Config remediation for {resource_type} with ID {resource_id}")

    return remediate_resource(resource_type, resource_id)


def handle_eventbridge_invocation(event):
    """
    Handle invocation from EventBridge rules.

    Extracts resource information from the EventBridge event and
    calls the remediation function.

    Args:
        event (dict): The EventBridge event

    Returns:
        dict: Response containing the remediation status
    """
    # Extract resource information from the EventBridge event detail
    detail = event.get("detail", {})
    resource_type = detail.get("resourceType", "")
    resource_id = detail.get("resourceId", "")

    logger.info(f"EventBridge remediation for {resource_type} with ID {resource_id}")

    return remediate_resource(resource_type, resource_id)


def remediate_resource(resource_type, resource_id):
    """
    Remediate the specified resource based on its type.

    This is the main orchestration function that:
    1. Captures the original state of the resource
    2. Calls the appropriate remediation function based on resource type
    3. Captures the remediated state if successful
    4. Logs the remediation action

    Args:
        resource_type (str): The type of AWS resource (e.g., AWS::EC2::Volume)
        resource_id (str): The ID of the resource to remediate

    Returns:
        dict: Response containing the remediation status
    """
    # Capture original state for evidence and auditing
    original_state = capture_original_state(resource_type, resource_id)

    # Perform remediation based on resource type
    if resource_type == "AWS::EC2::Volume":
        result = remediate_ebs_volume(resource_id)
    elif resource_type == "AWS::S3::Bucket":
        result = remediate_s3_bucket(resource_id)
    elif resource_type == "AWS::RDS::DBInstance":
        result = remediate_rds_instance(resource_id)
    else:
        result = {
            "status": "FAILED",
            "message": f"Unsupported resource type: {resource_type}",
        }

    # Capture remediated state for evidence if remediation was successful
    if result["status"] == "SUCCESS":
        remediated_state = capture_original_state(resource_type, resource_id)
        log_remediation(
            resource_type, resource_id, original_state, remediated_state, result
        )

    return {"statusCode": 200 if result["status"] == "SUCCESS" else 400, "body": result}


def remediate_ebs_volume(volume_id):
    """
    Remediate an unencrypted EBS volume by creating a snapshot,
    creating an encrypted copy, and replacing the original volume.

    This is a complex operation that involves:
    1. Checking if the volume is already encrypted
    2. Creating a snapshot of the unencrypted volume
    3. Creating a new encrypted volume from the snapshot
    4. Detaching the original volume and attaching the new one
    5. Copying tags from the original volume to the new one

    Args:
        volume_id (str): The ID of the EBS volume to remediate

    Returns:
        dict: Result of the remediation with status and message
    """
    try:
        # Get volume information
        volume_response = ec2_client.describe_volumes(VolumeIds=[volume_id])
        if not volume_response["Volumes"]:
            return {"status": "FAILED", "message": f"Volume {volume_id} not found"}

        volume = volume_response["Volumes"][0]

        # Check if already encrypted - no action needed if it is
        if volume.get("Encrypted", False):
            return {
                "status": "SUCCESS",
                "message": f"Volume {volume_id} is already encrypted",
            }

        # Get attached instance information - we need this to reattach the new volume
        attachments = volume.get("Attachments", [])
        if not attachments:
            return {
                "status": "FAILED",
                "message": f"Volume {volume_id} is not attached to any instance",
            }

        instance_id = attachments[0].get("InstanceId")
        device_name = attachments[0].get("Device")

        if not instance_id or not device_name:
            return {
                "status": "FAILED",
                "message": f"Could not determine instance or device for volume {volume_id}",
            }

        # Check if instance is running - we can only safely replace volumes on stopped instances
        instance_response = ec2_client.describe_instances(InstanceIds=[instance_id])
        instance_state = instance_response["Reservations"][0]["Instances"][0]["State"][
            "Name"
        ]

        if instance_state != "stopped":
            # We can't safely replace a volume on a running instance
            # In a real-world scenario, you might want to schedule this or notify
            return {
                "status": "FAILED",
                "message": f"Instance {instance_id} must be stopped to replace volume. Current state: {instance_state}",
            }

        # Create a snapshot of the volume - this preserves the data
        logger.info(f"Creating snapshot of volume {volume_id}")
        snapshot_response = ec2_client.create_snapshot(
            VolumeId=volume_id,
            Description=f"Snapshot for encryption remediation of {volume_id}",
        )
        snapshot_id = snapshot_response["SnapshotId"]

        # Wait for snapshot to complete - this can take some time
        logger.info(f"Waiting for snapshot {snapshot_id} to complete")
        ec2_client.get_waiter("snapshot_completed").wait(SnapshotIds=[snapshot_id])

        # Create an encrypted copy of the volume from the snapshot
        logger.info(f"Creating encrypted volume from snapshot {snapshot_id}")
        encryption_params = {
            "SnapshotId": snapshot_id,
            "VolumeType": volume.get("VolumeType", "gp2"),
            "Size": volume.get("Size"),
            "AvailabilityZone": volume.get("AvailabilityZone"),
            "Encrypted": True,
        }

        # Use custom KMS key if provided
        if KMS_KEY_ID:
            encryption_params["KmsKeyId"] = KMS_KEY_ID

        new_volume_response = ec2_client.create_volume(**encryption_params)
        new_volume_id = new_volume_response["VolumeId"]

        # Wait for volume to be available
        logger.info(f"Waiting for new volume {new_volume_id} to be available")
        ec2_client.get_waiter("volume_available").wait(VolumeIds=[new_volume_id])

        # Detach the original volume
        logger.info(f"Detaching original volume {volume_id}")
        ec2_client.detach_volume(VolumeId=volume_id)

        # Wait for volume to be available
        logger.info(f"Waiting for original volume {volume_id} to be available")
        ec2_client.get_waiter("volume_available").wait(VolumeIds=[volume_id])

        # Attach the new encrypted volume
        logger.info(
            f"Attaching new encrypted volume {new_volume_id} to instance {instance_id}"
        )
        ec2_client.attach_volume(
            VolumeId=new_volume_id, InstanceId=instance_id, Device=device_name
        )

        # Copy tags from original volume to new volume to maintain metadata
        if "Tags" in volume:
            logger.info(f"Copying tags from original volume to new volume")
            ec2_client.create_tags(Resources=[new_volume_id], Tags=volume["Tags"])

        return {
            "status": "SUCCESS",
            "message": f"Successfully replaced unencrypted volume {volume_id} with encrypted volume {new_volume_id}",
            "original_volume_id": volume_id,
            "new_volume_id": new_volume_id,
        }

    except Exception as e:
        logger.error(f"Error remediating EBS volume {volume_id}: {str(e)}")
        return {
            "status": "FAILED",
            "message": f"Error remediating EBS volume: {str(e)}",
        }


def remediate_s3_bucket(bucket_name):
    """
    Remediate an S3 bucket by enabling default encryption.

    This function:
    1. Checks if the bucket exists and is accessible
    2. Checks if encryption is already enabled
    3. Applies default encryption using AES256 or KMS

    Args:
        bucket_name (str): The name of the S3 bucket to remediate

    Returns:
        dict: Result of the remediation with status and message
    """
    try:
        # Check if bucket exists and is accessible
        try:
            s3_client.head_bucket(Bucket=bucket_name)
        except ClientError as e:
            return {
                "status": "FAILED",
                "message": f"Bucket {bucket_name} does not exist or you don't have permission to access it",
            }

        # Check current encryption configuration
        try:
            encryption = s3_client.get_bucket_encryption(Bucket=bucket_name)
            # Bucket already has encryption - no action needed
            return {
                "status": "SUCCESS",
                "message": f"Bucket {bucket_name} already has encryption enabled",
            }
        except ClientError as e:
            # Expected error if encryption is not configured
            if (
                e.response["Error"]["Code"]
                != "ServerSideEncryptionConfigurationNotFoundError"
            ):
                raise

        # Apply default encryption - using AES256 as the default method
        logger.info(f"Enabling default encryption for bucket {bucket_name}")
        encryption_config = {
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"},
                    "BucketKeyEnabled": True,
                }
            ]
        }

        # If KMS key is provided, use it instead of AES256
        if KMS_KEY_ID:
            logger.info(f"Using KMS key {KMS_KEY_ID} for bucket encryption")
            encryption_config["Rules"][0]["ApplyServerSideEncryptionByDefault"] = {
                "SSEAlgorithm": "aws:kms",
                "KMSMasterKeyID": KMS_KEY_ID,
            }

        # Apply the encryption configuration to the bucket
        s3_client.put_bucket_encryption(
            Bucket=bucket_name, ServerSideEncryptionConfiguration=encryption_config
        )

        return {
            "status": "SUCCESS",
            "message": f"Successfully enabled default encryption for bucket {bucket_name}",
        }

    except Exception as e:
        logger.error(f"Error remediating S3 bucket {bucket_name}: {str(e)}")
        return {"status": "FAILED", "message": f"Error remediating S3 bucket: {str(e)}"}


def remediate_rds_instance(db_instance_id):
    """
    For RDS instances, we can't directly enable encryption on an existing instance.
    Instead, we'll create a snapshot, create an encrypted copy, and restore from it.
    This is a complex operation that would require careful scheduling in production.

    For this lab, we only provide a recommendation rather than performing the actual remediation,
    as it would involve significant downtime and careful planning.

    Args:
        db_instance_id (str): The ID of the RDS instance to remediate

    Returns:
        dict: Result of the remediation (in this case, a recommendation)
    """
    try:
        # Get DB instance information
        db_response = rds_client.describe_db_instances(
            DBInstanceIdentifier=db_instance_id
        )
        if not db_response["DBInstances"]:
            return {
                "status": "FAILED",
                "message": f"DB instance {db_instance_id} not found",
            }

        db_instance = db_response["DBInstances"][0]

        # Check if already encrypted - no action needed if it is
        if db_instance.get("StorageEncrypted", False):
            return {
                "status": "SUCCESS",
                "message": f"DB instance {db_instance_id} is already encrypted",
            }

        # For RDS, we can't directly encrypt an existing instance
        # We would need to:
        # 1. Create a snapshot
        # 2. Copy the snapshot with encryption enabled
        # 3. Restore from the encrypted snapshot
        # 4. Update endpoints
        # 5. Delete the original instance

        # This is a complex operation that would require downtime and careful planning
        # For this lab, we'll just return a recommendation

        return {
            "status": "MANUAL_ACTION_REQUIRED",
            "message": f"RDS instance {db_instance_id} requires encryption. This requires a manual process: "
            f"1. Create a snapshot, 2. Create an encrypted copy of the snapshot, "
            f"3. Restore from the encrypted snapshot, 4. Update application endpoints, "
            f"5. Delete the original instance when safe to do so.",
        }

    except Exception as e:
        logger.error(f"Error processing RDS instance {db_instance_id}: {str(e)}")
        return {
            "status": "FAILED",
            "message": f"Error processing RDS instance: {str(e)}",
        }


def capture_original_state(resource_type, resource_id):
    """
    Capture the original state of a resource for evidence.

    This function retrieves the current configuration of a resource
    before any remediation actions are taken, for auditing and rollback purposes.

    Args:
        resource_type (str): The type of AWS resource
        resource_id (str): The ID of the resource

    Returns:
        dict: The original state of the resource
    """
    try:
        # Handle different resource types
        if resource_type == "AWS::EC2::Volume":
            # For EBS volumes, get the volume details
            response = ec2_client.describe_volumes(VolumeIds=[resource_id])
            return response["Volumes"][0] if response["Volumes"] else {}

        elif resource_type == "AWS::S3::Bucket":
            # For S3 buckets, get location and encryption settings
            bucket_details = {}

            # Get bucket location
            location = s3_client.get_bucket_location(Bucket=resource_id)
            bucket_details["Location"] = location.get("LocationConstraint", "us-east-1")

            # Try to get encryption settings - may not exist
            try:
                encryption = s3_client.get_bucket_encryption(Bucket=resource_id)
                bucket_details["Encryption"] = encryption.get(
                    "ServerSideEncryptionConfiguration", {}
                )
            except ClientError:
                bucket_details["Encryption"] = None

            return bucket_details

        elif resource_type == "AWS::RDS::DBInstance":
            # For RDS instances, get the instance details
            response = rds_client.describe_db_instances(
                DBInstanceIdentifier=resource_id
            )
            return response["DBInstances"][0] if response["DBInstances"] else {}

        return {}

    except Exception as e:
        logger.error(
            f"Error capturing original state for {resource_type} {resource_id}: {str(e)}"
        )
        return {}


def log_remediation(
    resource_type, resource_id, original_state, remediated_state, result
):
    """
    Log the remediation action and store evidence.

    This function:
    1. Creates a detailed record of the remediation action
    2. Logs the information to CloudWatch
    3. Stores the evidence in S3 (if configured)
    4. Sends a notification via SNS (if configured)

    Args:
        resource_type (str): The type of AWS resource
        resource_id (str): The ID of the resource
        original_state (dict): The original state of the resource
        remediated_state (dict): The state after remediation
        result (dict): The result of the remediation
    """
    timestamp = datetime.datetime.now().isoformat()

    # Create evidence record with all relevant information
    evidence = {
        "remediation_type": "Encryption Remediation",
        "resource_type": resource_type,
        "resource_id": resource_id,
        "timestamp": timestamp,
        "original_state": original_state,
        "remediated_state": remediated_state,
        "remediation_result": result,
    }

    # Log to CloudWatch for immediate visibility
    logger.info(f"Remediation completed: {json.dumps(evidence, default=str)}")

    # Store evidence in S3 if bucket is configured
    if EVIDENCE_BUCKET:
        try:
            s3_client = boto3.client("s3")
            # Create a unique key for the evidence file
            evidence_key = f"remediation-logs/encryption/{resource_type}/{resource_id}/{datetime.datetime.now().strftime('%Y-%m-%d-%H-%M-%S')}.json"

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

    # Send notification if SNS topic is configured
    if SNS_TOPIC_ARN:
        try:
            # Format a human-readable message for the notification
            message = f"""
SECURITY ALERT: Encryption Remediation

Resource Type: {resource_type}
Resource ID: {resource_id}
Timestamp: {timestamp}

Remediation Status: {result['status']}
Message: {result['message']}

This is an automated message from the Encryption Remediation function.
            """

            # Send the notification
            sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject=f"Encryption Remediated: {resource_type} {resource_id}",
                Message=message,
            )

            logger.info(f"Notification sent to {SNS_TOPIC_ARN}")
        except Exception as e:
            logger.error(f"Error sending notification: {str(e)}")
