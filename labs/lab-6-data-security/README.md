# Lab 6: Data Security

## Overview

This lab focuses on implementing comprehensive data security controls in AWS to protect sensitive information at rest and in transit. You will learn how to implement encryption, manage access controls, and monitor data access patterns to ensure compliance with security best practices and regulatory requirements.

## Learning Objectives

By completing this lab, you will be able to:

1. Implement encryption for data at rest using AWS KMS and service-specific encryption mechanisms
2. Configure encryption for data in transit using TLS/SSL
3. Implement data classification and tagging strategies
4. Set up secure data access patterns with appropriate IAM policies
5. Configure data access monitoring and auditing
6. Implement data loss prevention controls
7. Create automated remediation for data security violations

## Prerequisites

Before starting this lab, you should have:

- An AWS account with administrative access
- AWS CLI installed and configured
- Basic understanding of AWS services (S3, RDS, DynamoDB, KMS)
- Completed Lab 2: Identity and Access Management (recommended)
- Completed Lab 3: Security Automation with IaC (recommended)

## Estimated Time and Cost

- **Time to complete**: 3-4 hours
- **AWS cost**: $5-10 if resources are promptly cleaned up after the lab
  - Most resources are eligible for AWS Free Tier
  - KMS keys cost $1/month per key
  - CloudWatch Logs and CloudTrail may incur small charges

## Architecture Overview

This lab will guide you through building a secure data handling architecture that includes:

- Encrypted S3 buckets with appropriate access controls
- Encrypted RDS database with secure access patterns
- KMS key management with proper key rotation and access policies
- Data classification using resource tags
- CloudWatch monitoring for data access events
- Automated remediation for security violations

See the [architecture diagram](architecture-diagram.md) for a visual representation of the solution.

## Modules

The lab is divided into five modules:

1. **Module 1: Encryption Foundations** - Set up KMS keys and implement encryption for S3 and RDS
2. **Module 2: Data Classification** - Implement data classification using tags and enforce controls based on classification
3. **Module 3: Secure Access Patterns** - Configure IAM policies and resource policies for secure data access
4. **Module 4: Data Access Monitoring** - Set up CloudTrail, CloudWatch, and Macie for data access monitoring
5. **Module 5: Automated Remediation** - Implement automated remediation for data security violations

Follow the [step-by-step guide](step-by-step-guide.md) to complete each module.

## Validation

After completing the lab, use the [validation checklist](validation-checklist.md) to verify your implementation meets all security requirements.

## Advanced Challenges

Once you've completed the main lab, try the [advanced challenges](challenges.md) to further enhance your skills.

## Cleanup

To avoid ongoing charges, make sure to delete all resources created during this lab by following the cleanup instructions at the end of the step-by-step guide.

## Additional Resources

- [AWS KMS Developer Guide](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html)
- [AWS S3 Encryption Guide](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingEncryption.html)
- [AWS Database Encryption](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.Encryption.html)
- [AWS Macie Documentation](https://docs.aws.amazon.com/macie/latest/user/what-is-macie.html)
- [AWS Security Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html) 