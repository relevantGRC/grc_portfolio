# Lab 1: AWS Account Governance - Advanced Challenges

After completing the basic implementation in the step-by-step guide, take your AWS account governance knowledge to the next level with these advanced challenges. Each challenge builds upon the foundational security controls and introduces more sophisticated security architectures and automation.

## Challenge 1: Implement Automated Compliance Remediation

**Difficulty**: Intermediate

**Description**: Create an automated remediation framework that detects and fixes common compliance issues found by AWS Config.

**Steps**:
1. Create a Lambda function that automatically remediates non-compliant resources
2. Set up EventBridge rules to trigger the Lambda when compliance issues are detected
3. Implement remediation for at least three common issues:
   - S3 buckets with public access
   - Security groups with unrestricted access
   - Unencrypted EBS volumes

**Resources**:
- [AWS Security Hub Automated Response and Remediation](https://github.com/aws-samples/aws-security-hub-automated-response-and-remediation)
- [AWS Config Automation](https://docs.aws.amazon.com/config/latest/developerguide/remediation.html)

## Challenge 2: Deploy Security Controls Using AWS CDK

**Difficulty**: Intermediate

**Description**: Refactor the security controls implemented manually in the lab to be deployed as Infrastructure as Code using AWS CDK.

**Steps**:
1. Create a CDK project that implements all security controls from Lab 1
2. Implement the following using CDK:
   - IAM password policy
   - CloudTrail configuration
   - AWS Config setup with rules
   - Security Hub enablement
   - CloudWatch alarms
3. Deploy the stack and verify all controls are properly implemented

**Resources**:
- [AWS Control Tower Controls CDK](https://github.com/aws-samples/aws-control-tower-controls-cdk)
- [AWS CDK Examples](https://github.com/aws-samples/aws-cdk-examples)

## Challenge 3: Multi-Account Security with AWS Organizations

**Difficulty**: Advanced

**Description**: Extend the account governance controls to a multi-account environment using AWS Organizations and Control Tower.

**Steps**:
1. Set up AWS Organizations with at least one additional account
2. Implement Service Control Policies (SCPs) to enforce security guardrails
3. Configure CloudTrail, Config, and Security Hub for centralized security monitoring
4. Implement cross-account IAM roles for security administration
5. Deploy a dashboard to visualize security posture across accounts

**Resources**:
- [AWS Secure Environment Accelerator](https://github.com/aws-samples/aws-secure-environment-accelerator)
- [Baseline Environment on AWS](https://github.com/aws-samples/baseline-environment-on-aws)

## Challenge 4: Automated Security Incident Playbooks

**Difficulty**: Advanced

**Description**: Create automated incident response playbooks for common security events.

**Steps**:
1. Set up AWS Step Functions to orchestrate incident response workflows
2. Create playbooks for at least three security incidents:
   - Unauthorized API calls
   - Root account usage
   - Privilege escalation
3. Integrate with notification systems (e.g., email, Slack)
4. Document the incident response process

**Resources**:
- [AWS Customer Playbook Framework](https://github.com/aws-samples/aws-customer-playbook-framework)
- [AWS Control Tower Account Setup using Step Functions](https://github.com/aws-samples/aws-control-tower-account-setup-using-step-functions)

## Challenge 5: Build a Security Monitoring Dashboard

**Difficulty**: Advanced

**Description**: Implement a comprehensive security monitoring solution using Amazon OpenSearch and Kibana.

**Steps**:
1. Set up the SIEM on Amazon OpenSearch Service solution
2. Configure log ingestion from CloudTrail, VPC Flow Logs, and AWS WAF
3. Create custom dashboards for security monitoring
4. Implement alerts for suspicious activities
5. Document dashboard usage and alert response procedures

**Resources**:
- [SIEM on Amazon OpenSearch Service](https://github.com/aws-samples/siem-on-amazon-opensearch-service)

## Challenge 6: Implement a Secure Vault with AWS Nitro Enclaves

**Difficulty**: Expert

**Description**: Create a secure vault for storing and managing sensitive configuration data using AWS Nitro Enclaves.

**Steps**:
1. Set up an EC2 instance with Nitro Enclaves support
2. Implement a secure vault for storing sensitive credentials
3. Create an API for securely accessing vault contents
4. Implement proper authentication and authorization
5. Document the security architecture and threat model

**Resources**:
- [Sample Code for a Secure Vault using AWS Nitro Enclaves](https://github.com/aws-samples/sample-code-for-a-secure-vault-using-aws-nitro-enclaves)

## Reflection Questions

After completing one or more challenges, consider the following questions to deepen your understanding:

1. How does the automated implementation improve security compared to manual configuration?
2. What are the trade-offs between security, operational complexity, and cost in your implementation?
3. How would your implementation scale to hundreds or thousands of AWS accounts?
4. What additional monitoring or alerting would you implement in a production environment?
5. How would you adapt these controls for specific compliance frameworks (e.g., HIPAA, PCI DSS, FedRAMP)?

## Submission Guidelines

Document your challenge implementation in a format suitable for your GRC portfolio:

1. Architecture diagram showing your solution
2. Implementation details including code snippets or IaC templates
3. Explanation of security controls and their purpose
4. Discussion of challenges faced and how you overcame them
5. Screenshots of the deployed solution (with sensitive information redacted)

## Additional Resources

- [AWS Security Reference Architecture](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/welcome.html)
- [AWS Cloud Adoption Framework - Security Perspective](https://docs.aws.amazon.com/whitepapers/latest/aws-caf-security-perspective/aws-caf-security-perspective.html)
- [AWS Security Documentation](https://docs.aws.amazon.com/security/) 