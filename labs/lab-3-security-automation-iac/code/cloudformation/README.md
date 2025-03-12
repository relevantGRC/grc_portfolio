# CloudFormation Templates for Security Automation

This directory contains CloudFormation templates used in Lab 3: Security Automation with Infrastructure as Code. These templates are designed to implement security best practices and automated security controls.

## Available Templates

### 1. secure-vpc.yaml

A CloudFormation template that creates a secure VPC with private and public subnets, security groups, NACLs, and VPC flow logs.

**Features:**
- Multi-AZ deployment with public and private subnets
- Network ACLs with restricted inbound rules
- Security groups following the principle of least privilege
- VPC Flow Logs for network traffic monitoring
- NAT Gateway for secure outbound internet access from private subnets

**Usage:**
```bash
aws cloudformation deploy \
  --template-file secure-vpc.yaml \
  --stack-name secure-vpc \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    VpcCidr=10.0.0.0/16 \
    PublicSubnet1Cidr=10.0.0.0/24 \
    PublicSubnet2Cidr=10.0.1.0/24 \
    PrivateSubnet1Cidr=10.0.2.0/24 \
    PrivateSubnet2Cidr=10.0.3.0/24 \
    FlowLogRetention=14
```

### 2. custom-config-rule.yaml

A CloudFormation template that creates a custom AWS Config rule to check if EBS volumes are encrypted, along with auto-remediation capabilities.

**Features:**
- Custom Lambda function to evaluate EBS volume encryption
- AWS Config Rule that runs on configuration changes and on a schedule
- EventBridge rule to trigger remediation for non-compliant resources
- Auto-remediation Lambda function
- SNS notifications for compliance status changes

**Usage:**
```bash
aws cloudformation deploy \
  --template-file custom-config-rule.yaml \
  --stack-name ebs-encryption-rule \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    LambdaRoleName=ConfigCustomRuleLambdaRole \
    ConfigRuleName=ebs-volume-encryption-check
```

## Using These Templates

### Prerequisites

Before deploying these templates:

1. Ensure you have the AWS CLI installed and configured:
   ```bash
   aws --version
   aws configure
   ```

2. Verify you have sufficient permissions to create the resources in the templates.

3. If you're deploying in a production environment, review the templates carefully and consider:
   - Resource costs
   - IAM permissions granted
   - Security implications of the configurations

### Deployment Best Practices

1. **Test First**: Always deploy templates in a test environment before production.

2. **Use Parameters**: Customize templates using parameter overrides rather than modifying the templates directly.

3. **Use Stack Names with Environments**: Include environment names in your stack names (e.g., `secure-vpc-dev`, `secure-vpc-prod`).

4. **Enable Termination Protection**: For production stacks, enable termination protection:
   ```bash
   aws cloudformation update-termination-protection \
     --stack-name your-stack-name \
     --enable-termination-protection
   ```

5. **Use Change Sets**: For updates to existing stacks, use change sets to preview changes:
   ```bash
   aws cloudformation create-change-set \
     --stack-name your-stack-name \
     --template-body file://template.yaml \
     --change-set-name your-change-set
   ```

## Template Security Considerations

These templates create resources that affect your AWS account's security posture. Consider the following:

1. **IAM Roles and Policies**: Review all IAM roles and policies created by the templates and ensure they follow the principle of least privilege.

2. **Resource Access**: Ensure resources like S3 buckets, security groups, and KMS keys have appropriate access controls.

3. **Logging and Monitoring**: Enable appropriate logging and monitoring for all created resources.

4. **Regular Updates**: Periodically update templates to incorporate new security best practices and AWS features.

## Template Customization

If you need to customize these templates:

1. Make a copy of the original template.

2. Update the parameters section to include any new configuration options.

3. Modify the resources as needed, ensuring you maintain security best practices.

4. Validate the template before deployment:
   ```bash
   aws cloudformation validate-template \
     --template-body file://your-modified-template.yaml
   ```

5. Use a security scanning tool like cfn-nag to check for security issues:
   ```bash
   cfn_nag_scan --input-path your-modified-template.yaml
   ```

## Troubleshooting

Common issues and solutions:

1. **Stack Creation Failures**:
   - Check the stack events in the AWS Console or using CLI:
     ```bash
     aws cloudformation describe-stack-events --stack-name your-stack-name
     ```

2. **Parameter Validation Errors**:
   - Ensure parameter values meet the constraints defined in the template.

3. **IAM-Related Failures**:
   - Make sure to include `--capabilities CAPABILITY_IAM` or `CAPABILITY_NAMED_IAM` when deploying templates that create IAM resources.

4. **Resource Limits**:
   - Check if you've hit AWS service limits for resources being created.

## Adding New Templates

When adding new templates to this directory, please:

1. Follow the naming convention: `purpose-resource.yaml`
2. Include comprehensive descriptions and parameter details in the template
3. Update this README with details about the new template
4. Include usage examples
5. Validate and scan the template for security issues before committing

If you encounter any issues not covered here, please refer to the AWS CloudFormation documentation or open an issue in the lab repository. 