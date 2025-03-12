# CloudFormation Templates for Lab 2: Identity and Access Management

This directory contains CloudFormation templates that can be used to deploy the IAM resources required for Lab 2. These templates enable you to quickly implement best practices for identity and access management in AWS.

## Available Templates

### iam-resources.yaml

A comprehensive template that creates a complete IAM infrastructure including:

- IAM password policy with secure defaults
- IAM groups for different job functions with appropriate permissions
- IAM roles with proper trust relationships
- Custom policies and permission boundaries
- IAM Access Analyzer
- CloudWatch alarms for IAM activity monitoring
- SNS notification topics
- Optional SAML identity provider for federation

**Parameters:**
- `AdminEmail`: Email address for IAM notifications
- `MinPasswordLength`: Minimum length for IAM passwords (default: 14)
- `PasswordReusePrevention`: Number of previous passwords that cannot be reused (default: 24)
- `MaxPasswordAge`: Maximum age for passwords in days (default: 90)
- `CreateGroups`: Whether to create IAM groups (default: true)
- `CreateRoles`: Whether to create IAM roles (default: true)
- `CreatePolicies`: Whether to create custom IAM policies (default: true)
- `AllowExternalIdP`: Whether to create a SAML provider for federation (default: false)

## Deployment Instructions

### Using AWS Management Console

1. Sign in to the AWS Management Console
2. Navigate to the CloudFormation service
3. Click **Create stack**
4. Select **With new resources (standard)**
5. Under **Specify template**, choose **Upload a template file**
6. Click **Choose file** and select the template file
7. Click **Next**
8. Enter a stack name (e.g., `iam-resources`)
9. Configure parameters as needed
10. Click **Next**
11. Configure stack options as needed
12. Click **Next**
13. Review the configuration and click **Create stack**

### Using AWS CLI

```bash
aws cloudformation create-stack \
  --stack-name iam-resources \
  --template-body file://iam-resources.yaml \
  --parameters \
    ParameterKey=AdminEmail,ParameterValue=your-email@example.com \
    ParameterKey=MinPasswordLength,ParameterValue=14 \
    ParameterKey=PasswordReusePrevention,ParameterValue=24 \
    ParameterKey=MaxPasswordAge,ParameterValue=90 \
    ParameterKey=CreateGroups,ParameterValue=true \
    ParameterKey=CreateRoles,ParameterValue=true \
    ParameterKey=CreatePolicies,ParameterValue=true \
    ParameterKey=AllowExternalIdP,ParameterValue=false \
  --capabilities CAPABILITY_NAMED_IAM
```

## Customization

You can customize the CloudFormation templates to fit your specific requirements:

- Modify policy definitions to align with your security requirements
- Add additional IAM groups or roles for your organization's needs
- Customize the permission boundaries to enforce your security guardrails
- Update the CloudWatch alarms to monitor specific IAM activities

## Best Practices

When using these templates, consider the following best practices:

- Review all IAM policies before deployment to ensure they follow the principle of least privilege
- Ensure the AdminEmail parameter is set to a monitored email address
- Consider enabling the SAML provider only if you have an external identity provider configured
- After deployment, verify that all resources were created correctly and validate permissions
- Regularly review and update the deployed resources to maintain security

## Clean Up

To remove all resources created by the template:

```bash
aws cloudformation delete-stack --stack-name iam-resources
```

**Note**: Deleting the CloudFormation stack will remove all IAM resources created by the template. If you've added users or made manual changes to the IAM resources, you may need to clean those up separately. 