"""
Custom AWS Config Rule to check if resources have the required tags.

This function evaluates whether AWS resources have the required tags specified in
the rule parameters. It supports checking for both tag keys and specific key-value pairs.
"""

import json


# Helper Functions
def evaluate_compliance(configuration_item, required_tags, required_tag_values):
    """Evaluate whether the resource has the required tags and values."""

    if (
        "tags" not in configuration_item["configuration"]
        or not configuration_item["configuration"]["tags"]
    ):
        return "NON_COMPLIANT", "Resource has no tags"

    resource_tags = configuration_item["configuration"]["tags"]

    # Check if all required tags are present
    missing_tags = [tag for tag in required_tags if tag not in resource_tags]
    if missing_tags:
        return "NON_COMPLIANT", f"Missing required tags: {', '.join(missing_tags)}"

    # Check if required tag values match
    non_compliant_values = []
    for tag_key, expected_value in required_tag_values.items():
        if tag_key in resource_tags:
            if expected_value != "" and resource_tags[tag_key] != expected_value:
                non_compliant_values.append(
                    f"{tag_key} should be '{expected_value}' but is '{resource_tags[tag_key]}'"
                )

    if non_compliant_values:
        return (
            "NON_COMPLIANT",
            f"Tag values don't match requirements: {', '.join(non_compliant_values)}",
        )

    return "COMPLIANT", "Resource has all required tags with correct values"


def get_configuration_item(invoking_event):
    """Extract the configuration item from the invoking event."""
    try:
        return json.loads(invoking_event)["configurationItem"]
    except Exception as e:
        raise Exception(
            f"Could not get configuration item from invoking event: {str(e)}"
        )


def get_rule_parameters(rule_parameters):
    """Parse and validate the rule parameters."""
    if not rule_parameters:
        raise Exception("Rule parameters are required")

    try:
        params = json.loads(rule_parameters)
        required_tags = params.get("requiredTags", "").split(",")
        required_tags = [tag.strip() for tag in required_tags if tag.strip()]

        required_tag_values = {}
        if "requiredTagValues" in params:
            tag_values = json.loads(params.get("requiredTagValues", "{}"))
            required_tag_values = {k: v for k, v in tag_values.items() if k.strip()}

        return required_tags, required_tag_values
    except Exception as e:
        raise Exception(f"Error parsing rule parameters: {str(e)}")


def lambda_handler(event, context):
    """Main Lambda handler function for evaluating resource compliance."""
    print(f"Event: {json.dumps(event)}")

    invoking_event = event["invokingEvent"]
    rule_parameters = event.get("ruleParameters", "")

    try:
        # Get configuration item and rule parameters
        configuration_item = get_configuration_item(invoking_event)
        required_tags, required_tag_values = get_rule_parameters(rule_parameters)

        if configuration_item["configurationItemStatus"] == "ResourceDeleted":
            return {
                "compliance_type": "NOT_APPLICABLE",
                "annotation": "Resource was deleted",
            }

        # Check if this is a supported resource type
        supported_resource_types = [
            "AWS::EC2::Instance",
            "AWS::EC2::Volume",
            "AWS::S3::Bucket",
            "AWS::RDS::DBInstance",
            "AWS::DynamoDB::Table",
            "AWS::Lambda::Function",
        ]

        if configuration_item["resourceType"] not in supported_resource_types:
            return {
                "compliance_type": "NOT_APPLICABLE",
                "annotation": f"Resource type {configuration_item['resourceType']} is not supported",
            }

        # Evaluate compliance
        compliance_type, annotation = evaluate_compliance(
            configuration_item, required_tags, required_tag_values
        )

        # Prepare the evaluation response
        evaluation = {
            "compliance_type": compliance_type,
            "annotation": annotation,
            "resource_id": configuration_item["resourceId"],
            "resource_type": configuration_item["resourceType"],
        }

        print(f"Evaluation result: {json.dumps(evaluation)}")
        return evaluation

    except Exception as e:
        print(f"Error evaluating compliance: {str(e)}")
        raise


def put_evaluations(config_client, event, result_token, evaluations):
    """Submit evaluation results to AWS Config."""
    response = config_client.put_evaluations(
        Evaluations=[
            {
                "ComplianceResourceType": evaluation["resource_type"],
                "ComplianceResourceId": evaluation["resource_id"],
                "ComplianceType": evaluation["compliance_type"],
                "Annotation": evaluation["annotation"],
                "OrderingTimestamp": json.loads(event["invokingEvent"])[
                    "notificationCreationTime"
                ],
            }
            for evaluation in evaluations
        ],
        ResultToken=result_token,
    )
    return response
