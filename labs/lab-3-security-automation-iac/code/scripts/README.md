# Security Automation Scripts

This directory contains scripts for implementing and managing security automation in the context of Lab 3: Security Automation with Infrastructure as Code.

## Available Scripts

### 1. setup-security-cicd.sh

A script to set up a CI/CD pipeline with security checks for CloudFormation templates.

**Usage:**
```bash
./setup-security-cicd.sh [options]
```

**Options:**
- `-r, --region REGION` - AWS region (default: us-east-1)
- `-s, --stack STACK_NAME` - CloudFormation stack name (default: security-cicd-pipeline)
- `-n, --repo REPO_NAME` - CodeCommit repository name (default: security-iac-repo)
- `-b, --branch BRANCH_NAME` - Repository branch name (default: main)
- `-d, --template-dir DIR` - Directory containing CloudFormation templates (default: ../cloudformation)
- `-h, --help` - Display help message

**Features:**
- Creates a CodeCommit repository for infrastructure code
- Sets up an S3 bucket for artifacts with appropriate security controls
- Deploys a CI/CD pipeline using AWS CodePipeline
- Configures security scanning using cfn-nag and CloudFormation validation
- Sets up notifications for pipeline events

**Requirements:**
- AWS CLI installed and configured
- Sufficient IAM permissions to create resources

### 2. cloudformation-guard-policies.guard

A CloudFormation Guard policy file containing rules to enforce security best practices in CloudFormation templates.

**Usage:**
```bash
# Install cfn-guard
pip install cloudformation-guard

# Run the policy against a template
cfn-guard validate -r cloudformation-guard-policies.guard -t your-template.yaml
```

**Features:**
- Rules for EC2 instance security (IMDSv2, public IP restrictions, monitoring)
- Rules for S3 bucket security (encryption, access blocking, versioning, logging)
- Rules for RDS security (encryption, public access, deletion protection)
- Rules for IAM security (permission boundaries, policy restrictions)
- Rules for Security Group configurations
- Rules for VPC security (flow logs)
- Rules for CloudTrail configuration
- Rules for Lambda function security

**Requirements:**
- CloudFormation Guard installed

## Using These Scripts

Before using any script:

1. Make sure you have the AWS CLI installed and configured with appropriate credentials.
2. Make the script executable:
   ```bash
   chmod +x script-name.sh
   ```
3. Review the script to understand what it will do in your environment.
4. Run the script with the `--help` flag to see available options.

## Script Security Considerations

These scripts create and modify AWS resources that may impact your AWS account's security posture. Always:

1. Review the scripts before running them
2. Run scripts in a test/lab account first
3. Understand the permissions required for the scripts to run
4. Monitor resource creation and costs
5. Be prepared to clean up resources after testing

## Adding Your Own Scripts

When adding new scripts to this directory, please follow these guidelines:

1. Include a descriptive comment header explaining the script's purpose
2. Add proper error handling and input validation
3. Use environment variables or command-line arguments for configuration
4. Make scripts idempotent (can be run multiple times safely)
5. Add the script details to this README

## Troubleshooting

**Common Issues:**

1. **Permission Denied when Running Scripts**
   - Make sure the script is executable: `chmod +x script-name.sh`

2. **AWS CLI Errors**
   - Ensure AWS CLI is installed and configured: `aws --version`
   - Check your credentials: `aws sts get-caller-identity`

3. **Resource Creation Failures**
   - Check CloudWatch Logs for detailed error messages
   - Verify your account limits for resources being created
   - Check IAM permissions for the operations being performed

4. **CloudFormation Guard Errors**
   - Ensure you have the latest version installed
   - Check rule syntax for any errors
   - Verify template formatting is correct

If you encounter any issues not covered here, please refer to the AWS documentation or open an issue in the lab repository. 