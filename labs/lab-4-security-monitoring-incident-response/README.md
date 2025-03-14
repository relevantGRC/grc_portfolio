# Lab 4: Security Monitoring and Incident Response

## Learning Objectives

By the end of this lab, you will be able to:

1. Design and implement a comprehensive security monitoring solution in AWS
2. Configure automated alerting for security events
3. Develop incident response playbooks for common security scenarios
4. Implement security dashboards for real-time visibility
5. Create automation for incident response actions
6. Conduct security incident simulations and response exercises

## AWS Services Used

- AWS CloudTrail
- Amazon CloudWatch
- AWS Security Hub
- Amazon GuardDuty
- AWS Config
- Amazon EventBridge
- AWS Lambda
- Amazon SNS
- AWS Systems Manager
- Amazon S3
- AWS ChatBot (optional)

## Estimated Time to Complete

3-4 hours

## AWS Free Tier Usage

Most services used in this lab are either included in the AWS Free Tier or can be used with minimal cost if you follow the cleanup instructions. Some specific considerations:

- **AWS GuardDuty**: 30-day free trial for new accounts
- **AWS Security Hub**: 30-day free trial for new accounts
- **CloudTrail**: First trail is free
- **Lambda**: 1 million free requests per month
- **CloudWatch**: Basic monitoring is free, detailed monitoring and custom metrics have costs

## Prerequisites

1. An AWS account with administrative access
2. AWS CLI installed and configured
3. Basic knowledge of AWS security services
4. Completion of [Lab 1 (Account Governance)](../lab-1-account-governance), [Lab 2 (Identity and Access Management)](../lab-2-identity-access-management), and [Lab 3 (Security Automation with IaC)](../lab-3-security-automation-iac) is recommended for full context

## Architecture Overview

This lab implements a comprehensive security monitoring and incident response architecture in AWS:


The architecture includes:
- Centralized logging with CloudTrail and CloudWatch
- Threat detection with GuardDuty and Security Hub
- Automated alerting through SNS and EventBridge
- Incident response automation with Lambda and Systems Manager
- Security dashboards for visualization and monitoring

## Lab Components

- [**Step-by-Step Guide**](step-by-step-guide.md): Detailed instructions for implementing the security monitoring and incident response solution
- [**Validation Checklist**](validation-checklist.md): Criteria to verify successful implementation
- [**Advanced Challenges**](challenges.md): Additional exercises to enhance your skills

### Code Components

#### CloudFormation Templates
- [Security Group Remediation](code/scripts/ssm-documents/host-isolation.json): Systems Manager automation document for isolating potentially compromised EC2 instances

#### Lambda Functions
- [Compromised IAM Credentials Responder](code/scripts/lambda-functions/compromised-iam-credentials-responder.py): Function to automatically respond to potentially compromised IAM credentials

#### Incident Response Playbooks
- [Compromised Credentials Playbook](code/scripts/playbooks/compromised-credentials-playbook.md): Detailed playbook for responding to compromised IAM credentials

## Module Overview

### Module 1: Centralized Logging and Monitoring
- Configure CloudTrail for comprehensive API logging
- Set up CloudWatch Log Groups with metric filters
- Create CloudWatch Alarms for security events
- Implement CloudWatch Dashboards for security visibility

### Module 2: Threat Detection and Alerting
- Enable and configure GuardDuty
- Set up Security Hub and enable compliance standards
- Configure AWS Config rules for security compliance
- Implement SNS topics and subscriptions for notifications
- Create EventBridge rules for security events

### Module 3: Incident Response Automation
- Develop Lambda functions for automated response
- Create Systems Manager Automation documents
- Configure EventBridge rules to trigger response actions
- Implement notification escalation procedures

### Module 4: Incident Response Playbooks
- Create playbooks for common security incidents
- Document investigation procedures
- Implement containment and eradication strategies
- Define recovery procedures
- Establish post-incident review processes

### Module 5: Security Incident Simulations
- Simulate common security events
- Practice incident response procedures
- Test and validate automated responses
- Conduct tabletop exercises

## Skills Demonstrated

Upon completion of this lab, you will have demonstrated the following skills:

- Designing and implementing a comprehensive security monitoring solution
- Configuring automated detection and alerting for security events
- Developing and implementing incident response procedures
- Creating automation for security incident response
- Building security dashboards for visualization and reporting
- Testing and validating security monitoring and response capabilities

## Next Steps

After completing this lab, consider exploring:
- [Lab 5: Security Compliance and Reporting](../lab-5-security-compliance-reporting) (coming soon)
- Advanced security monitoring with third-party tools
- Integration with SIEM solutions
- Machine learning-based threat detection 