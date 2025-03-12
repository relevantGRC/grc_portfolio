# AWS Account Governance CloudFormation Template

This directory contains a comprehensive CloudFormation template that implements the AWS account governance controls described in Lab 1. The template automates the deployment of security best practices for AWS accounts.

## Template Overview

The `account-governance.yaml` template implements the following security controls:

- **IAM Password Policy** - Enforces strong password requirements
- **IAM Admin User** - Creates a secure administrative user
- **CloudTrail** - Enables comprehensive AWS API logging
- **AWS Config** - Sets up configuration monitoring with security rules
- **IAM Access Analyzer** - Identifies unintended resource access
- **CloudWatch Alarms** - Configures security monitoring alerts
- **SNS Notifications** - Sends email alerts for security events
- **AWS Budget** - Creates cost monitoring and alerting

## Prerequisites

Before deploying this template, you should have:

1. AWS account with permissions to create all the resources in the template
2. An email address to receive security and budget notifications
3. Basic familiarity with AWS CloudFormation

## Deployment Instructions

### Using AWS Management Console

1. Sign in to the AWS Management Console and navigate to CloudFormation
2. Click "Create stack" > "With new resources (standard)"
3. Under "Specify template", select "Upload a template file"
4. Click "Choose file" and select the `account-governance.yaml` file
5. Click "Next"
6. Enter a Stack name (e.g., "GRC-Lab-Account-Governance")
7. Fill in the required parameters:
   - **NotificationEmail**: Email address to receive security alerts
   - **CloudTrailBucketName**: Globally unique name for the CloudTrail S3 bucket (e.g., "cloudtrail-logs-[account-id]")
   - **ConfigBucketName**: Globally unique name for the AWS Config S3 bucket (e.g., "config-logs-[account-id]")
   - **MonthlyBudgetAmount**: Your monthly budget amount in USD (default: 100)
8. Click "Next", review the stack options, and click "Next" again
9. Review the configuration, acknowledge IAM resource creation, and click "Create stack"
10. Wait for the stack creation to complete (approximately 5-10 minutes)

### Using AWS CLI

```bash
aws cloudformation create-stack \
  --stack-name GRC-Lab-Account-Governance \
  --template-body file://account-governance.yaml \
  --parameters \
    ParameterKey=NotificationEmail,ParameterValue=your.email@example.com \
    ParameterKey=CloudTrailBucketName,ParameterValue=cloudtrail-logs-123456789012 \
    ParameterKey=ConfigBucketName,ParameterValue=config-logs-123456789012 \
    ParameterKey=MonthlyBudgetAmount,ParameterValue=100 \
  --capabilities CAPABILITY_NAMED_IAM
```

## Post-Deployment Steps

After deploying the template:

1. **Confirm SNS subscription**: Check your email and confirm the subscription to receive security alerts
2. **Set up MFA for the admin user**: CloudFormation cannot automatically set up MFA, so you'll need to manually configure it
3. **Verify CloudTrail is logging**: Check the CloudTrail console to ensure events are being recorded
4. **Review AWS Config rules**: Check the AWS Config console to review the compliance status of your resources

## Template Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| NotificationEmail | Email address to receive security notifications | None | Yes |
| CloudTrailBucketName | Name of the S3 bucket for CloudTrail logs (must be globally unique) | None | Yes |
| ConfigBucketName | Name of the S3 bucket for AWS Config logs (must be globally unique) | None | Yes |
| MonthlyBudgetAmount | Monthly budget amount in USD | 100 | No |

## Template Outputs

| Output | Description |
|--------|-------------|
| AdminUserName | Name of the created IAM admin user |
| CloudTrailName | Name of the CloudTrail trail |
| CloudTrailS3Bucket | S3 bucket storing CloudTrail logs |
| ConfigS3Bucket | S3 bucket storing AWS Config snapshots |
| SecurityAlertsTopic | SNS Topic ARN for security alerts |

## Security Considerations

- The template creates an IAM user with administrative privileges. Ensure you follow security best practices by setting up MFA and rotating credentials regularly.
- S3 buckets created by this template have public access blocked but review the bucket policies for any specific security requirements.
- Review the CloudWatch alarms and metric filters to ensure they meet your specific security monitoring needs.

## Cleanup

To remove all resources created by this template:

1. Go to the CloudFormation console
2. Select the stack you created
3. Click "Delete" and confirm the deletion
4. Note: The S3 buckets have a Retain deletion policy and won't be automatically deleted to prevent data loss

Alternatively, using AWS CLI:

```bash
aws cloudformation delete-stack --stack-name GRC-Lab-Account-Governance
```

To completely clean up, you'll need to manually empty and delete the S3 buckets after the stack deletion completes.

## Troubleshooting

- **Template validation errors**: Ensure you're using the latest version of the template and check for any syntax errors.
- **IAM permissions**: Ensure you have sufficient permissions to create all the resources in the template.
- **S3 bucket names**: If creation fails due to S3 bucket names, try different names as they must be globally unique.
- **CloudWatch Logs**: If CloudWatch alarms fail to create, ensure that CloudTrail is correctly configured and sending logs to CloudWatch Logs.

## Further Resources

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/best-practices/)
- [AWS CloudFormation Security Controls](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/security-controls.html) 