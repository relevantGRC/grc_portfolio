#!/bin/bash

# =========================================================================
# Setup Playbooks Script
# =========================================================================
# This script creates the directory structure and initial playbook files
# for the incident response lab. It generates a comprehensive playbook for
# handling compromised IAM credentials, which includes sections for:
# - Incident overview and classification
# - Detection sources
# - Initial response actions
# - Investigation process
# - Containment, eradication, and recovery steps
# - Post-incident activities
# =========================================================================

# Set up colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print script header
echo -e "${BLUE}=== Setting up Incident Response Playbooks ===${NC}"

# Create the playbooks directory if it doesn't exist
echo -e "${YELLOW}Creating playbooks directory...${NC}"
mkdir -p playbooks
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Playbooks directory created successfully.${NC}"
else
    echo -e "${RED}Failed to create playbooks directory.${NC}"
    exit 1
fi

# Define the path for the compromised credentials playbook
PLAYBOOK_PATH="playbooks/compromised-credentials-playbook.md"
echo -e "${YELLOW}Creating compromised credentials playbook at ${PLAYBOOK_PATH}...${NC}"

# Generate the playbook content with detailed sections
cat > ${PLAYBOOK_PATH} << 'EOL'
# Incident Response Playbook: Compromised IAM Credentials

## Overview
This playbook outlines the process for responding to suspected or confirmed compromised AWS IAM credentials. Compromised credentials can lead to unauthorized access, data breaches, resource abuse, and financial impact.

## Incident Classification
- **Severity**: High
- **Impact**: Potential unauthorized access to AWS resources, data exposure, and financial impact
- **Response Time SLA**: Initial response within 30 minutes of detection

## Detection Sources
- AWS CloudTrail logs showing unusual API calls
- AWS GuardDuty findings related to IAM entities
- AWS Config rule violations
- Security information and event management (SIEM) alerts
- Unusual billing activity
- Third-party security monitoring tools

## Initial Response Actions

### 1. Acknowledge and Assess the Alert (SLA: 15 minutes)
- Document the initial alert details
- Verify the alert is not a false positive
- Determine which IAM principal (user or role) is potentially compromised
- Identify the AWS account(s) affected

### 2. Establish an Incident Response Channel (SLA: 15 minutes)
- Create a dedicated communication channel (e.g., Slack channel, Teams chat)
- Notify the incident response team
- Designate an incident commander
- Begin documenting all actions taken

## Investigation Process

### 1. Activity Timeline Analysis (SLA: 1 hour)
- Review CloudTrail logs for the affected IAM principal
- Document all actions taken by the potentially compromised credentials
- Identify the first suspicious activity and establish a timeline
- Determine the scope of access and potential impact
- Look for indicators of privilege escalation

### 2. Resource Assessment (SLA: 2 hours)
- Identify all AWS resources accessed or modified
- Check for unauthorized resources created (EC2 instances, Lambda functions, etc.)
- Review S3 bucket access logs for data exfiltration
- Check for changes to IAM policies or new IAM entities
- Review network traffic logs for unusual patterns

### 3. Attack Vector Analysis (SLA: 4 hours)
- Determine how the credentials were compromised
- Check for public exposure of access keys in code repositories
- Review for signs of phishing or social engineering
- Assess if the compromise is related to a broader attack

## Containment, Eradication, and Recovery

### 1. Immediate Containment (SLA: 30 minutes)
- Deactivate or delete the affected access keys
- Apply restrictive IAM policies to the affected user/role
- Revoke active sessions for the compromised principal
- Isolate affected resources if necessary

### 2. Credential Rotation (SLA: 2 hours)
- Rotate all potentially affected credentials
- Update credentials in authorized applications and services
- Verify that old credentials are no longer in use

### 3. Remove Unauthorized Resources (SLA: 4 hours)
- Terminate unauthorized EC2 instances or containers
- Remove unauthorized IAM users, roles, or policies
- Delete unauthorized resources created by the attacker
- Revert unauthorized changes to configurations

### 4. Secure Account and Resources (SLA: 8 hours)
- Implement or review MFA for all IAM users
- Review and tighten IAM permissions using least privilege
- Ensure CloudTrail logging is properly configured
- Enable additional security monitoring as needed

## Post-Incident Activities

### 1. Documentation and Reporting
- Complete the incident report with timeline and actions taken
- Document lessons learned and areas for improvement
- Prepare reports for management and compliance requirements

### 2. Process Improvement
- Update security policies and procedures based on lessons learned
- Enhance detection capabilities for similar incidents
- Conduct training to prevent similar incidents

### 3. Preventative Measures
- Implement regular key rotation policies
- Set up automated monitoring for exposed credentials
- Enhance IAM security posture with SCPs and permission boundaries
- Conduct security awareness training for developers and administrators

## Automation Opportunities
- **Detection**: Automated GuardDuty and CloudTrail monitoring
- **Containment**: Automated credential deactivation and session revocation
- **Investigation**: Automated timeline creation and resource assessment
- **Recovery**: Automated credential rotation and configuration verification

## Metrics and KPIs
- Time to detect credential compromise
- Time to contain the incident
- Number of resources affected
- Time to full recovery
- Percentage of automated vs. manual response actions
EOL

# Check if the playbook was created successfully
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Compromised credentials playbook created successfully.${NC}"
else
    echo -e "${RED}Failed to create compromised credentials playbook.${NC}"
    exit 1
fi

# Print completion message
echo -e "${BLUE}=== Playbook setup complete ===${NC}"
echo -e "${GREEN}You can find the playbooks in the 'playbooks' directory.${NC}" 