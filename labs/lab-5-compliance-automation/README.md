# Lab 5: Compliance Automation

## Learning Objectives

By the end of this lab, you will be able to:

1. Implement automated compliance controls using AWS Config
2. Create and deploy custom AWS Config rules
3. Build compliance dashboards and reports
4. Set up continuous compliance monitoring
5. Implement automated remediation for compliance violations
6. Create compliance documentation and evidence collection mechanisms

## AWS Services Used

- AWS Config
- AWS CloudFormation
- AWS Lambda
- Systems Manager Automation
- Amazon EventBridge
- AWS Security Hub
- Amazon SNS
- Amazon S3
- AWS CloudTrail
- Amazon CloudWatch

## Estimated Time to Complete

3-4 hours

## AWS Free Tier Usage

Most services used in this lab are eligible for the AWS Free Tier with some limitations:

- **AWS Config**: Free Tier includes 85 config items per month; additional usage will incur charges
- **AWS Lambda**: 1 million free requests per month
- **Amazon SNS**: First 1 million requests free
- **CloudWatch**: Basic monitoring is free

## Prerequisites

1. An AWS account with administrative access
2. AWS CLI installed and configured
3. Basic knowledge of AWS security services
4. Completion of [Lab 1 (Account Governance)](../lab-1-account-governance), [Lab 2 (Identity and Access Management)](../lab-2-identity-access-management), [Lab 3 (Security Automation with IaC)](../lab-3-security-automation-iac), and [Lab 4 (Security Monitoring and Incident Response)](../lab-4-security-monitoring-incident-response) is recommended for full context

## Architecture Overview

This lab implements an automated compliance solution in AWS:


The architecture includes:
- AWS Config for compliance rule evaluation
- Custom rule implementation with Lambda
- Automated remediation with Systems Manager Automation
- Compliance dashboards for visibility
- Continuous monitoring and alerting for compliance events
- Secure evidence collection and reporting

## Lab Components

- [**Step-by-Step Guide**](step-by-step-guide.md): Detailed instructions for implementing the compliance automation solution
- [**Validation Checklist**](validation-checklist.md): Criteria to verify successful implementation
- [**Advanced Challenges**](challenges.md): Additional exercises to enhance your skills

### Code Components

#### CloudFormation Templates
- [Config Rules Stack](code/cloudformation/config-rules-stack.yaml): Deploys a set of AWS Config rules for common compliance requirements
- [Compliance Dashboard](code/cloudformation/compliance-dashboard.yaml): Creates dashboards for compliance visibility

#### Terraform Configurations
- [AWS Config Setup](code/terraform/aws-config-setup.tf): Sets up AWS Config with standard compliance rules
- [Automated Remediation](code/terraform/automated-remediation.tf): Implements automatic remediation for compliance violations

#### Lambda Functions
- [Custom Config Rules](code/scripts/lambda-functions): Custom rule implementations
- [Remediation Functions](code/scripts/remediation): Functions for automated remediation

#### Scripts
- [Compliance Report Generator](code/scripts/report-generator): Scripts for creating compliance reports
- [Evidence Collection](code/scripts/evidence-collector): Scripts for collecting and storing compliance evidence

## Module Overview

### Module 1: Compliance as Code Foundations
- Set up AWS Config with recording and delivery
- Implement security baselines as Config rules
- Create S3 bucket for compliance evidence
- Set up notifications for compliance events

### Module 2: Custom Compliance Rules
- Develop Lambda-based custom AWS Config rules
- Implement resource tagging compliance
- Create data protection compliance rules
- Set up security boundary enforcement

### Module 3: Automated Remediation
- Implement auto-remediation for security group violations
- Create automatic responses for S3 bucket policy issues
- Set up IAM policy violation remediation
- Configure encryption compliance enforcement

### Module 4: Compliance Dashboards and Reporting
- Build CloudWatch dashboards for compliance status
- Implement automated report generation
- Create evidence collection mechanisms
- Set up audit-ready documentation system

### Module 5: Compliance Frameworks Implementation
- Map rules to common compliance frameworks (CIS, NIST, PCI)
- Create framework-specific conformance packs
- Implement multi-framework compliance mapping
- Build framework-specific dashboards

## Skills Demonstrated

Upon completion of this lab, you will have demonstrated the following skills:

- Implementing infrastructure compliance controls as code
- Building automated compliance monitoring solutions
- Implementing automated remediation for compliance violations
- Creating compliance dashboards and reports
- Mapping technical controls to compliance frameworks
- Developing audit-ready evidence collection mechanisms

## Next Steps

After completing this lab, consider exploring:
- [Lab 6: Data Security](../lab-6-data-security) (coming soon)
- Advanced compliance frameworks like NIST 800-53 or PCI DSS
- Integration with GRC tools
- Continuous compliance strategies across multiple accounts 