"""
Compromised IAM Credentials Responder Lambda Function

This Lambda function automatically responds to potential IAM credential compromise events.
It is triggered by GuardDuty findings or CloudTrail events that indicate suspicious IAM activity.

The function performs the following actions:
1. Analyzes the event to determine the affected IAM principal
2. Implements immediate containment by disabling access keys or applying restrictive policies
3. Collects evidence about the potentially malicious activity
4. Sends notifications to security teams
5. Creates a detailed incident report
"""

import datetime
import json
import logging
import os

import boto3

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
iam_client = boto3.client("iam")
sns_client = boto3.client("sns")
cloudtrail_client = boto3.client("cloudtrail")
s3_client = boto3.client("s3")
guardduty_client = boto3.client("guardduty")
ssm_client = boto3.client("ssm")

# Get environment variables
# SNS_TOPIC_ARN: ARN of the SNS topic for sending security notifications
# EVIDENCE_BUCKET: S3 bucket name for storing incident evidence
# INCIDENT_WORKFLOW_DOCUMENT: SSM document name for incident response workflow
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN", "")
EVIDENCE_BUCKET = os.environ.get("EVIDENCE_BUCKET", "")
INCIDENT_WORKFLOW_DOCUMENT = os.environ.get("INCIDENT_WORKFLOW_DOCUMENT", "")


def lambda_handler(event, context):
    """
    Main Lambda handler function for responding to compromised IAM credentials.

    This function determines the type of event (GuardDuty finding or CloudTrail event)
    and routes it to the appropriate handler function.

    Args:
        event (dict): The event triggering the Lambda function
        context (object): Lambda context object

    Returns:
        dict: Response containing the remediation status
    """
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        # Determine the event type and route to appropriate handler
        if (
            "detail" in event
            and "type" in event["detail"]
            and "GuardDuty" in event["detail"]["type"]
        ):
            # This is a GuardDuty finding
            return handle_guardduty_finding(event)
        elif (
            "detail" in event
            and "eventSource" in event["detail"]
            and event["detail"]["eventSource"] == "iam.amazonaws.com"
        ):
            # This is a CloudTrail event for IAM
            return handle_cloudtrail_event(event)
        else:
            error_msg = "Unsupported event format"
            logger.error(error_msg)
            return {"statusCode": 400, "body": json.dumps({"error": error_msg})}
    except Exception as e:
        logger.error(f"Error processing event: {str(e)}")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}


def handle_guardduty_finding(event):
    """
    Handle GuardDuty findings related to compromised credentials.

    This function extracts information from GuardDuty findings,
    identifies the affected IAM principal, and takes appropriate
    containment actions.

    Args:
        event (dict): The GuardDuty finding event

    Returns:
        dict: Response containing the remediation status
    """
    try:
        # Extract finding details
        finding_id = event["detail"]["id"]
        finding_type = event["detail"]["type"]
        severity = event["detail"]["severity"]

        # Get the full finding details from GuardDuty
        finding = guardduty_client.get_findings(
            DetectorId=event["detail"]["detectorId"], FindingIds=[finding_id]
        )["Findings"][0]

        # Extract IAM principal information
        principal_type = None
        principal_id = None

        if "Resource" in finding and "AccessKeyDetails" in finding["Resource"]:
            principal_type = "user"
            principal_id = finding["Resource"]["AccessKeyDetails"].get("UserName")
            access_key_id = finding["Resource"]["AccessKeyDetails"].get("AccessKeyId")
        elif "Resource" in finding and "IamInstanceProfile" in finding["Resource"]:
            principal_type = "role"
            principal_id = finding["Resource"]["IamInstanceProfile"].get("Name")

        if not principal_id:
            logger.warning(
                f"Could not determine affected IAM principal from finding {finding_id}"
            )
            return {
                "statusCode": 400,
                "body": json.dumps(
                    {"error": "Could not determine affected IAM principal"}
                ),
            }

        # Collect evidence before taking containment actions
        evidence = collect_evidence(principal_type, principal_id)

        # Take containment actions based on the finding type and severity
        containment_actions = []

        if severity >= 7.0:  # High severity
            if principal_type == "user" and access_key_id:
                # Disable the access key
                iam_client.update_access_key(
                    UserName=principal_id, AccessKeyId=access_key_id, Status="Inactive"
                )
                containment_actions.append(
                    f"Disabled access key {access_key_id} for user {principal_id}"
                )

            # Apply a restrictive policy to the principal
            apply_restrictive_policy(principal_type, principal_id)
            containment_actions.append(
                f"Applied restrictive policy to {principal_type} {principal_id}"
            )

        # Create an incident report
        incident_report = {
            "timestamp": datetime.datetime.now().isoformat(),
            "finding_id": finding_id,
            "finding_type": finding_type,
            "severity": severity,
            "principal_type": principal_type,
            "principal_id": principal_id,
            "evidence": evidence,
            "containment_actions": containment_actions,
        }

        # Store the incident report
        store_incident_report(incident_report)

        # Send notification
        send_notification(incident_report)

        # Trigger incident response workflow if configured
        if INCIDENT_WORKFLOW_DOCUMENT:
            trigger_incident_workflow(incident_report)

        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "message": "Successfully responded to GuardDuty finding",
                    "finding_id": finding_id,
                    "containment_actions": containment_actions,
                }
            ),
        }
    except Exception as e:
        logger.error(f"Error handling GuardDuty finding: {str(e)}")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}


def handle_cloudtrail_event(event):
    """
    Handle CloudTrail events related to suspicious IAM activity.

    This function analyzes CloudTrail events for suspicious IAM actions,
    such as policy changes, new access keys, or unusual API calls.

    Args:
        event (dict): The CloudTrail event

    Returns:
        dict: Response containing the remediation status
    """
    try:
        # Extract event details
        event_name = event["detail"]["eventName"]
        event_time = event["detail"]["eventTime"]
        user_identity = event["detail"]["userIdentity"]

        # Determine the principal type and ID
        principal_type = user_identity.get("type", "").lower()
        principal_id = None

        if principal_type == "iamuser":
            principal_id = user_identity.get("userName")
        elif principal_type == "assumedrole":
            principal_id = (
                user_identity.get("sessionContext", {})
                .get("sessionIssuer", {})
                .get("userName")
            )

        if not principal_id:
            logger.warning(
                f"Could not determine affected IAM principal from CloudTrail event {event_name}"
            )
            return {
                "statusCode": 400,
                "body": json.dumps(
                    {"error": "Could not determine affected IAM principal"}
                ),
            }

        # Collect evidence
        evidence = collect_evidence(principal_type, principal_id)

        # Determine if this is a suspicious event that requires containment
        requires_containment = is_suspicious_event(event_name, event["detail"])

        containment_actions = []
        if requires_containment:
            # Apply containment actions
            if event_name == "CreateAccessKey":
                # If a new access key was created, disable it
                response_elements = event["detail"].get("responseElements", {})
                if "accessKey" in response_elements:
                    access_key_id = response_elements["accessKey"].get("accessKeyId")
                    if access_key_id:
                        iam_client.update_access_key(
                            UserName=principal_id,
                            AccessKeyId=access_key_id,
                            Status="Inactive",
                        )
                        containment_actions.append(
                            f"Disabled newly created access key {access_key_id} for user {principal_id}"
                        )

            # Apply a restrictive policy to the principal
            apply_restrictive_policy(principal_type, principal_id)
            containment_actions.append(
                f"Applied restrictive policy to {principal_type} {principal_id}"
            )

        # Create an incident report
        incident_report = {
            "timestamp": datetime.datetime.now().isoformat(),
            "event_name": event_name,
            "event_time": event_time,
            "principal_type": principal_type,
            "principal_id": principal_id,
            "evidence": evidence,
            "containment_actions": containment_actions,
        }

        # Store the incident report
        store_incident_report(incident_report)

        # Send notification
        send_notification(incident_report)

        # Trigger incident response workflow if configured
        if INCIDENT_WORKFLOW_DOCUMENT and requires_containment:
            trigger_incident_workflow(incident_report)

        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "message": "Successfully processed CloudTrail event",
                    "event_name": event_name,
                    "containment_actions": containment_actions,
                }
            ),
        }
    except Exception as e:
        logger.error(f"Error handling CloudTrail event: {str(e)}")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}


def collect_evidence(principal_type, principal_id):
    """
    Collect evidence about the IAM principal's recent activity.

    This function gathers information about the principal's recent API calls,
    access patterns, and configuration to support investigation.

    Args:
        principal_type (str): The type of IAM principal ('user' or 'role')
        principal_id (str): The ID of the IAM principal

    Returns:
        dict: Evidence collected about the principal
    """
    evidence = {
        "principal_type": principal_type,
        "principal_id": principal_id,
        "timestamp": datetime.datetime.now().isoformat(),
        "recent_activity": [],
        "configuration": {},
    }

    try:
        # Get recent CloudTrail events for this principal
        end_time = datetime.datetime.now()
        start_time = end_time - datetime.timedelta(hours=24)

        # Lookup attribute depends on principal type
        lookup_attribute = {
            "AttributeKey": "Username" if principal_type == "user" else "ResourceName",
            "AttributeValue": principal_id,
        }

        events = cloudtrail_client.lookup_events(
            LookupAttributes=[lookup_attribute],
            StartTime=start_time,
            EndTime=end_time,
            MaxResults=50,
        )

        evidence["recent_activity"] = events.get("Events", [])

        # Get principal configuration
        if principal_type == "user":
            user = iam_client.get_user(UserName=principal_id)
            evidence["configuration"]["user"] = user.get("User", {})

            # Get access keys
            access_keys = iam_client.list_access_keys(UserName=principal_id)
            evidence["configuration"]["access_keys"] = access_keys.get(
                "AccessKeyMetadata", []
            )

            # Get attached policies
            attached_policies = iam_client.list_attached_user_policies(
                UserName=principal_id
            )
            evidence["configuration"]["attached_policies"] = attached_policies.get(
                "AttachedPolicies", []
            )
        elif principal_type == "role":
            role = iam_client.get_role(RoleName=principal_id)
            evidence["configuration"]["role"] = role.get("Role", {})

            # Get attached policies
            attached_policies = iam_client.list_attached_role_policies(
                RoleName=principal_id
            )
            evidence["configuration"]["attached_policies"] = attached_policies.get(
                "AttachedPolicies", []
            )
    except Exception as e:
        logger.error(f"Error collecting evidence: {str(e)}")
        evidence["error"] = str(e)

    return evidence


def is_suspicious_event(event_name, event_detail):
    """
    Determine if a CloudTrail event is suspicious and requires containment.

    This function analyzes the event name and details to identify potentially
    malicious activities that warrant immediate containment.

    Args:
        event_name (str): The name of the CloudTrail event
        event_detail (dict): The details of the CloudTrail event

    Returns:
        bool: True if the event is suspicious, False otherwise
    """
    # List of suspicious IAM-related events that might indicate compromise
    suspicious_events = [
        "CreateAccessKey",
        "CreateLoginProfile",
        "UpdateLoginProfile",
        "AttachUserPolicy",
        "AttachRolePolicy",
        "PutUserPolicy",
        "PutRolePolicy",
        "CreatePolicyVersion",
        "SetDefaultPolicyVersion",
    ]

    # Check if the event is in the list of suspicious events
    if event_name in suspicious_events:
        return True

    # Additional logic for specific events could be added here
    # For example, checking if a policy grants admin privileges

    return False


def apply_restrictive_policy(principal_type, principal_id):
    """
    Apply a restrictive policy to the IAM principal as a containment measure.

    This function creates and attaches a deny-all policy to the affected
    principal to prevent further unauthorized actions.

    Args:
        principal_type (str): The type of IAM principal ('user' or 'role')
        principal_id (str): The ID of the IAM principal
    """
    try:
        # Create a deny-all inline policy
        policy_name = (
            f"SecurityContainment-{datetime.datetime.now().strftime('%Y%m%d%H%M%S')}"
        )
        policy_document = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Deny",
                    "Action": "*",
                    "Resource": "*",
                    "Condition": {
                        "StringNotEquals": {
                            "aws:PrincipalTag/SecurityException": "true"
                        }
                    },
                }
            ],
        }

        # Apply the policy based on principal type
        if principal_type == "user":
            iam_client.put_user_policy(
                UserName=principal_id,
                PolicyName=policy_name,
                PolicyDocument=json.dumps(policy_document),
            )
        elif principal_type == "role":
            iam_client.put_role_policy(
                RoleName=principal_id,
                PolicyName=policy_name,
                PolicyDocument=json.dumps(policy_document),
            )

        logger.info(
            f"Applied restrictive policy {policy_name} to {principal_type} {principal_id}"
        )
    except Exception as e:
        logger.error(f"Error applying restrictive policy: {str(e)}")
        raise


def store_incident_report(incident_report):
    """
    Store the incident report in the evidence bucket.

    This function saves a detailed incident report to S3 for
    future reference and investigation.

    Args:
        incident_report (dict): The incident report to store
    """
    if not EVIDENCE_BUCKET:
        logger.warning("No evidence bucket specified, skipping incident report storage")
        return

    try:
        # Create a unique key for the incident report
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d-%H-%M-%S")
        principal_type = incident_report.get("principal_type", "unknown")
        principal_id = incident_report.get("principal_id", "unknown")

        report_key = f"incident-reports/iam-credentials/{principal_type}/{principal_id}/{timestamp}.json"

        # Upload the incident report to S3
        s3_client.put_object(
            Bucket=EVIDENCE_BUCKET,
            Key=report_key,
            Body=json.dumps(incident_report, default=str),
            ContentType="application/json",
            ServerSideEncryption="AES256",
        )

        logger.info(f"Incident report saved to s3://{EVIDENCE_BUCKET}/{report_key}")
    except Exception as e:
        logger.error(f"Error storing incident report: {str(e)}")


def send_notification(incident_report):
    """
    Send a notification about the incident.

    This function creates a human-readable message about the incident
    and sends it via SNS to notify security teams.

    Args:
        incident_report (dict): The incident report
    """
    if not SNS_TOPIC_ARN:
        logger.warning("No SNS topic ARN specified, skipping notification")
        return

    try:
        # Format the notification message
        principal_type = incident_report.get("principal_type", "unknown")
        principal_id = incident_report.get("principal_id", "unknown")

        subject = f"SECURITY ALERT: Potential Compromised IAM Credentials - {principal_type} {principal_id}"

        message = f"""
SECURITY ALERT: Potential Compromised IAM Credentials

Principal Type: {principal_type}
Principal ID: {principal_id}
Timestamp: {incident_report.get('timestamp', 'unknown')}

Containment Actions Taken:
{chr(10).join(['- ' + action for action in incident_report.get('containment_actions', ['None'])])}

This is an automated message from the Compromised IAM Credentials Responder.
Please investigate this incident immediately.
        """

        # Send the notification
        sns_client.publish(TopicArn=SNS_TOPIC_ARN, Subject=subject, Message=message)

        logger.info(f"Notification sent to {SNS_TOPIC_ARN}")
    except Exception as e:
        logger.error(f"Error sending notification: {str(e)}")


def trigger_incident_workflow(incident_report):
    """
    Trigger an automated incident response workflow.

    This function starts an SSM Automation document to orchestrate
    the incident response process according to the organization's playbook.

    Args:
        incident_report (dict): The incident report
    """
    try:
        # Start the SSM automation document
        response = ssm_client.start_automation_execution(
            DocumentName=INCIDENT_WORKFLOW_DOCUMENT,
            Parameters={
                "PrincipalType": [incident_report.get("principal_type", "unknown")],
                "PrincipalId": [incident_report.get("principal_id", "unknown")],
                "IncidentTimestamp": [
                    incident_report.get(
                        "timestamp", datetime.datetime.now().isoformat()
                    )
                ],
                "EvidenceBucket": [EVIDENCE_BUCKET] if EVIDENCE_BUCKET else ["none"],
            },
        )

        logger.info(
            f"Triggered incident workflow {INCIDENT_WORKFLOW_DOCUMENT}, execution ID: {response.get('AutomationExecutionId')}"
        )
    except Exception as e:
        logger.error(f"Error triggering incident workflow: {str(e)}")
