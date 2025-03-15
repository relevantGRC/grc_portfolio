"""Mock AWS services for testing."""

import os
from unittest import mock


def setup_mocked_aws_environment():
    """Set up AWS environment variables and mock boto3 clients."""
    # Set AWS environment variables for testing
    os.environ["AWS_DEFAULT_REGION"] = "us-east-1"
    os.environ["AWS_ACCESS_KEY_ID"] = "test-key"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "test-secret"

    # Create a mock patch for boto3.client
    boto3_client_patch = mock.patch("boto3.client")
    boto3_client_patch.start()

    # Return the patch to be stopped later
    return boto3_client_patch
