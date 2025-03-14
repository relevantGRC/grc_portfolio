#!/usr/bin/env python3
"""
Network Security Testing Script for Lab 8: Infrastructure and Network Protection

This script performs various network security tests to validate the implementation
of security controls in the AWS infrastructure. It tests VPC security groups,
NACLs, WAF rules, and network connectivity.
"""

import json
import logging
import sys
from concurrent.futures import ThreadPoolExecutor

import boto3
import requests
from botocore.exceptions import ClientError

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler("network_security_test.log"),
    ],
)
logger = logging.getLogger(__name__)


class NetworkSecurityTester:
    def __init__(self, environment):
        """Initialize the network security tester with AWS clients."""
        self.environment = environment
        self.ec2 = boto3.client("ec2")
        self.elbv2 = boto3.client("elbv2")
        self.wafv2 = boto3.client("wafv2")
        self.guardduty = boto3.client("guardduty")
        self.cloudwatch = boto3.client("cloudwatch")

    def test_vpc_connectivity(self):
        """Test VPC connectivity between tiers."""
        try:
            logger.info("Testing VPC connectivity...")

            # Get VPC resources
            vpcs = self.ec2.describe_vpcs(
                Filters=[{"Name": "tag:Environment", "Values": [self.environment]}]
            )["Vpcs"]

            if not vpcs:
                logger.error("No VPC found for environment %s", self.environment)
                return False

            vpc_id = vpcs[0]["VpcId"]

            # Test subnet connectivity
            subnets = self.ec2.describe_subnets(
                Filters=[{"Name": "vpc-id", "Values": [vpc_id]}]
            )["Subnets"]

            for subnet in subnets:
                logger.info("Testing connectivity for subnet %s", subnet["SubnetId"])
                self._test_subnet_connectivity(subnet["SubnetId"])

            return True

        except ClientError as e:
            logger.error("Error testing VPC connectivity: %s", e)
            return False

    def test_security_groups(self):
        """Test security group configurations."""
        try:
            logger.info("Testing security group configurations...")

            # Get security groups
            security_groups = self.ec2.describe_security_groups(
                Filters=[{"Name": "tag:Environment", "Values": [self.environment]}]
            )["SecurityGroups"]

            for sg in security_groups:
                logger.info("Testing security group %s", sg["GroupId"])
                self._validate_security_group_rules(sg)

            return True

        except ClientError as e:
            logger.error("Error testing security groups: %s", e)
            return False

    def test_waf_rules(self, alb_url):
        """Test WAF rule effectiveness."""
        try:
            logger.info("Testing WAF rules...")

            # Test SQL injection protection
            sqli_test = f"{alb_url}?id=1' OR '1'='1"
            response = requests.get(sqli_test)
            if response.status_code == 403:
                logger.info("SQL injection protection working")
            else:
                logger.warning("SQL injection protection may not be effective")

            # Test XSS protection
            xss_test = f"{alb_url}?input=<script>alert('xss')</script>"
            response = requests.get(xss_test)
            if response.status_code == 403:
                logger.info("XSS protection working")
            else:
                logger.warning("XSS protection may not be effective")

            # Test rate limiting
            with ThreadPoolExecutor(max_workers=10) as executor:
                futures = [executor.submit(requests.get, alb_url) for _ in range(100)]
                responses = [f.result() for f in futures]
                if any(r.status_code == 429 for r in responses):
                    logger.info("Rate limiting working")
                else:
                    logger.warning("Rate limiting may not be effective")

            return True

        except Exception as e:
            logger.error("Error testing WAF rules: %s", e)
            return False

    def test_network_monitoring(self):
        """Test network monitoring and alerting."""
        try:
            logger.info("Testing network monitoring...")

            # Check GuardDuty
            detectors = self.guardduty.list_detectors()
            if not detectors["DetectorIds"]:
                logger.error("GuardDuty not enabled")
                return False

            # Check CloudWatch metrics
            metrics = self.cloudwatch.list_metrics(
                Namespace=f"{self.environment}/NetworkTraffic"
            )
            if not metrics["Metrics"]:
                logger.warning("No custom network metrics found")

            # Check VPC Flow Logs
            flow_logs = self.ec2.describe_flow_logs()
            if not flow_logs["FlowLogs"]:
                logger.warning("VPC Flow Logs not enabled")

            return True

        except ClientError as e:
            logger.error("Error testing network monitoring: %s", e)
            return False

    def _test_subnet_connectivity(self, subnet_id):
        """Test connectivity for a specific subnet."""
        try:
            # Get route table
            route_tables = self.ec2.describe_route_tables(
                Filters=[{"Name": "association.subnet-id", "Values": [subnet_id]}]
            )["RouteTables"]

            if not route_tables:
                logger.warning("No route table associated with subnet %s", subnet_id)
                return

            # Validate routes
            routes = route_tables[0]["Routes"]
            for route in routes:
                if "DestinationCidrBlock" in route:
                    logger.info(
                        "Route found: %s -> %s",
                        route.get("DestinationCidrBlock"),
                        route.get("GatewayId", route.get("NatGatewayId", "Unknown")),
                    )

        except ClientError as e:
            logger.error("Error testing subnet connectivity: %s", e)

    def _validate_security_group_rules(self, security_group):
        """Validate security group rules."""
        # Check inbound rules
        for rule in security_group["IpPermissions"]:
            if rule.get("IpRanges"):
                for ip_range in rule["IpRanges"]:
                    if ip_range["CidrIp"] == "0.0.0.0/0":
                        logger.warning(
                            "Security group %s has open inbound rule: %s",
                            security_group["GroupId"],
                            json.dumps(rule),
                        )

        # Check outbound rules
        for rule in security_group["IpPermissionsEgress"]:
            if rule.get("IpRanges"):
                for ip_range in rule["IpRanges"]:
                    if ip_range["CidrIp"] == "0.0.0.0/0":
                        logger.warning(
                            "Security group %s has open outbound rule: %s",
                            security_group["GroupId"],
                            json.dumps(rule),
                        )


def main():
    """Main function to run network security tests."""
    if len(sys.argv) != 3:
        print("Usage: network_security_test.py <environment> <alb_url>")
        sys.exit(1)

    environment = sys.argv[1]
    alb_url = sys.argv[2]

    tester = NetworkSecurityTester(environment)
    success = True

    try:
        # Run tests
        logger.info("Starting network security tests...")

        if not tester.test_vpc_connectivity():
            logger.error("VPC connectivity test failed")
            success = False

        if not tester.test_security_groups():
            logger.error("Security group test failed")
            success = False

        if not tester.test_waf_rules(alb_url):
            logger.error("WAF rules test failed")
            success = False

        if not tester.test_network_monitoring():
            logger.error("Network monitoring test failed")
            success = False

        # Final results
        if success:
            logger.info("All network security tests completed successfully")
        else:
            logger.error("Some network security tests failed")
            sys.exit(1)

    except Exception as e:
        logger.error("Error during network security testing: %s", e)
        sys.exit(1)


if __name__ == "__main__":
    main()
