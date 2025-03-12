# Lab 3: Security Automation with Infrastructure as Code - Step-by-Step Guide

This guide provides detailed instructions for implementing security automation with Infrastructure as Code (IaC). By following these steps, you will learn how to create secure infrastructure templates, automate compliance validation, build security checks into CI/CD pipelines, create remediation workflows, and implement policy as code.

## Module 1: Security Controls as Code

### 1.1 Create a Secure VPC Infrastructure Template with CloudFormation

1. Navigate to the CloudFormation directory:
   ```bash
   cd labs/lab-3-security-automation-iac/code/cloudformation
   ```

2. Create a new file named `secure-vpc.yaml` with the following content:
   ```yaml
   # See the code in the CloudFormation directory
   ```

3. Review the security features in the template:
   - Network ACLs to filter traffic
   - Private subnets with restrictive routing
   - VPC Flow Logs enabled
   - Security Groups with least privilege rules

4. Deploy the template using AWS CLI:
   ```bash
   aws cloudformation deploy \
     --template-file secure-vpc.yaml \
     --stack-name secure-vpc \
     --parameter-overrides VpcCidr=10.0.0.0/16 \
     --capabilities CAPABILITY_IAM
   ```

5. Verify the deployment:
   ```bash
   aws cloudformation describe-stacks --stack-name secure-vpc
   ```

### 1.2 Implement Secure S3 Bucket with Terraform

1. Navigate to the Terraform directory:
   ```bash
   cd ../terraform
   ```

2. Create a new file named `secure-s3.tf` with the following content:
   ```hcl
   # See the code in the Terraform directory
   ```

3. Initialize the Terraform directory:
   ```bash
   terraform init
   ```

4. Apply the Terraform configuration:
   ```bash
   terraform apply
   ```

5. Review the security features implemented:
   - Server-side encryption
   - Public access blocks
   - Versioning enabled
   - Access logging
   - Resource policies

### 1.3 Create a Security Baseline CloudFormation Template

1. Navigate back to the CloudFormation directory:
   ```bash
   cd ../cloudformation
   ```

2. Create a template named `security-baseline.yaml` that implements AWS security best practices:
   ```yaml
   # See the code in the CloudFormation directory
   ```

3. Review the security baseline components:
   - CloudTrail configuration
   - AWS Config setup
   - CloudWatch Alarms for security events
   - IAM password policy and roles

4. Deploy the security baseline:
   ```bash
   aws cloudformation deploy \
     --template-file security-baseline.yaml \
     --stack-name security-baseline \
     --capabilities CAPABILITY_NAMED_IAM
   ```

## Module 2: Automated Compliance Validation

### 2.1 Create a Custom AWS Config Rule with CloudFormation

1. Create a template named `custom-config-rules.yaml`:
   ```yaml
   # See the code in the CloudFormation directory
   ```

2. Review the custom AWS Config rule details:
   - Rule definition for S3 bucket encryption
   - AWS Lambda function to evaluate compliance
   - IAM role for Config rule execution

3. Deploy the template:
   ```bash
   aws cloudformation deploy \
     --template-file custom-config-rules.yaml \
     --stack-name custom-config-rules \
     --capabilities CAPABILITY_IAM
   ```

### 2.2 Implement Security Hub Integration

1. Create a template named `security-hub-integration.yaml`:
   ```yaml
   # See the code in the CloudFormation directory
   ```

2. Deploy the Security Hub integration:
   ```bash
   aws cloudformation deploy \
     --template-file security-hub-integration.yaml \
     --stack-name security-hub-integration \
     --capabilities CAPABILITY_IAM
   ```

3. Verify Security Hub is receiving findings:
   ```bash
   aws securityhub get-findings --filter '{"RecordState":[{"Value":"ACTIVE","Comparison":"EQUALS"}]}' --max-items 5
   ```

### 2.3 Implement cfn-nag for CloudFormation Templates

1. Install cfn-nag:
   ```bash
   gem install cfn-nag
   ```

2. Test cfn-nag on your template:
   ```bash
   cfn_nag_scan --input-path secure-vpc.yaml
   ```

3. Create a script named `validate-templates.sh` in the scripts directory:
   ```bash
   cd ../../scripts
   touch validate-templates.sh
   chmod +x validate-templates.sh
   ```

4. Add the following content to the script:
   ```bash
   # See the code in the scripts directory
   ```

5. Run the validation script:
   ```bash
   ./validate-templates.sh ../cloudformation/
   ```

6. Review the validation output and fix any identified issues.

## Module 3: CI/CD Pipeline with Security Checks

### 3.1 Create a CodePipeline for Infrastructure Deployment

1. Create a template named `secure-ci-cd-pipeline.yaml`:
   ```yaml
   # See the code in the CloudFormation directory
   ```

2. Deploy the CI/CD pipeline:
   ```bash
   aws cloudformation deploy \
     --template-file secure-ci-cd-pipeline.yaml \
     --stack-name secure-ci-cd-pipeline \
     --capabilities CAPABILITY_IAM
   ```

### 3.2 Implement Security Checks in CodeBuild

1. Create a `buildspec.yml` file for CodeBuild:
   ```yaml
   version: 0.2
   phases:
     install:
       runtime-versions:
         python: 3.9
       commands:
         - pip install cfn-lint checkov
         - gem install cfn-nag
     pre_build:
       commands:
         - echo "Running security checks on CloudFormation templates"
         - cfn-lint templates/*.yaml
         - cfn_nag_scan --input-path templates/
         - checkov -d templates/ --framework cloudformation
     build:
       commands:
         - echo "Security validation passed, proceeding with deployment"
         - aws cloudformation package --template-file main.yaml --s3-bucket ${ARTIFACT_BUCKET} --output-template-file packaged.yaml
     post_build:
       commands:
         - echo "Build completed on `date`"
   artifacts:
     files:
       - packaged.yaml
       - templates/*
   ```

2. Create a test CloudFormation template with security issues to validate the pipeline:
   ```bash
   cd ../cloudformation
   touch insecure-template.yaml
   ```

3. Add the following content to `insecure-template.yaml`:
   ```yaml
   # See the code in the CloudFormation directory
   ```

4. Push the code to your repository to trigger the pipeline, and observe the security checks failing.

### 3.3 Create a Security Dashboard

1. Create a template named `security-dashboard.yaml`:
   ```yaml
   # See the code in the CloudFormation directory
   ```

2. Deploy the security dashboard:
   ```bash
   aws cloudformation deploy \
     --template-file security-dashboard.yaml \
     --stack-name security-dashboard \
     --capabilities CAPABILITY_IAM
   ```

## Module 4: Security Remediation Automation

### 4.1 Create an Auto-Remediation Lambda Function

1. Navigate to the scripts directory:
   ```bash
   cd ../../scripts
   ```

2. Create a Lambda function for auto-remediation:
   ```bash
   mkdir lambda-functions
   cd lambda-functions
   touch auto-remediate-s3.py
   ```

3. Add the following content to the Lambda function:
   ```python
   # See the code in the scripts/lambda-functions directory
   ```

4. Create a CloudFormation template to deploy the Lambda function:
   ```bash
   cd ../../cloudformation
   touch auto-remediation.yaml
   ```

5. Add the following content to the template:
   ```yaml
   # See the code in the CloudFormation directory
   ```

6. Deploy the auto-remediation solution:
   ```bash
   aws cloudformation deploy \
     --template-file auto-remediation.yaml \
     --stack-name auto-remediation \
     --capabilities CAPABILITY_IAM
   ```

### 4.2 Implement EventBridge Rules for Security Events

1. Create a template named `security-event-rules.yaml`:
   ```yaml
   # See the code in the CloudFormation directory
   ```

2. Deploy the EventBridge rules:
   ```bash
   aws cloudformation deploy \
     --template-file security-event-rules.yaml \
     --stack-name security-event-rules \
     --capabilities CAPABILITY_IAM
   ```

### 4.3 Create a Terraform Remediation Module

1. Navigate to the Terraform directory:
   ```bash
   cd ../terraform
   mkdir remediation-modules
   cd remediation-modules
   touch s3-remediation.tf
   ```

2. Add the following content to the Terraform module:
   ```hcl
   # See the code in the Terraform directory
   ```

3. Create a main.tf file to use the module:
   ```bash
   cd ..
   touch remediation-main.tf
   ```

4. Add the following content:
   ```hcl
   # See the code in the Terraform directory
   ```

5. Initialize and apply the Terraform configuration:
   ```bash
   terraform init
   terraform apply
   ```

## Module 5: Policy as Code

### 5.1 Implement AWS Config Conformance Packs

1. Navigate to the CloudFormation directory:
   ```bash
   cd ../cloudformation
   ```

2. Create a template named `conformance-pack.yaml`:
   ```yaml
   # See the code in the CloudFormation directory
   ```

3. Deploy the conformance pack:
   ```bash
   aws cloudformation deploy \
     --template-file conformance-pack.yaml \
     --stack-name conformance-pack \
     --capabilities CAPABILITY_IAM
   ```

### 5.2 Implement Service Control Policies (SCPs)

1. Create a template named `service-control-policies.yaml`:
   ```yaml
   # See the code in the CloudFormation directory
   ```

2. Deploy the template (Note: This requires AWS Organizations to be set up):
   ```bash
   aws cloudformation deploy \
     --template-file service-control-policies.yaml \
     --stack-name service-control-policies \
     --capabilities CAPABILITY_IAM
   ```

### 5.3 Create an AWS CloudFormation Guard Policy

1. Navigate to the scripts directory:
   ```bash
   cd ../../scripts
   mkdir cfn-guard-rules
   cd cfn-guard-rules
   touch s3-security-rules.guard
   ```

2. Add the following content to the Guard rule file:
   ```
   let s3_buckets = Resources.*[ Type == 'AWS::S3::Bucket' ]

   rule s3_bucket_encryption_enabled when %s3_buckets !empty {
     %s3_buckets.Properties {
       BucketEncryption exists
       BucketEncryption.ServerSideEncryptionConfiguration[*] {
         ServerSideEncryptionByDefault.SSEAlgorithm exists
         ServerSideEncryptionByDefault.SSEAlgorithm == 'AES256' or ServerSideEncryptionByDefault.SSEAlgorithm == 'aws:kms'
       }
     }
   }

   rule s3_bucket_versioning_enabled when %s3_buckets !empty {
     %s3_buckets.Properties {
       VersioningConfiguration exists
       VersioningConfiguration.Status == 'Enabled'
     }
   }

   rule s3_bucket_logging_enabled when %s3_buckets !empty {
     %s3_buckets.Properties {
       LoggingConfiguration exists
     }
   }

   rule s3_bucket_public_access_blocked when %s3_buckets !empty {
     %s3_buckets.Properties {
       PublicAccessBlockConfiguration exists
       PublicAccessBlockConfiguration.BlockPublicAcls == true
       PublicAccessBlockConfiguration.BlockPublicPolicy == true
       PublicAccessBlockConfiguration.IgnorePublicAcls == true
       PublicAccessBlockConfiguration.RestrictPublicBuckets == true
     }
   }
   ```

3. Create a script to validate CloudFormation templates against Guard rules:
   ```bash
   cd ..
   touch validate-with-guard.sh
   chmod +x validate-with-guard.sh
   ```

4. Add the following content to the script:
   ```bash
   #!/bin/bash
   # Script to validate CloudFormation templates against Guard rules

   if [ $# -lt 2 ]; then
       echo "Usage: $0 <template-file> <rules-file>"
       exit 1
   fi

   TEMPLATE_FILE=$1
   RULES_FILE=$2

   # Check if cfn-guard is installed
   if ! command -v cfn-guard &> /dev/null; then
       echo "cfn-guard is not installed. Installing..."
       pip install cfn-guard
   fi

   # Validate the template
   echo "Validating $TEMPLATE_FILE against $RULES_FILE..."
   cfn-guard validate -r $RULES_FILE -t $TEMPLATE_FILE
   ```

5. Test the Guard rules:
   ```bash
   ./validate-with-guard.sh ../cloudformation/secure-s3.yaml cfn-guard-rules/s3-security-rules.guard
   ```

## Validation

Congratulations! You have successfully implemented security automation with Infrastructure as Code. To verify your implementation, proceed to the [Validation Checklist](validation-checklist.md).

## Troubleshooting

- **CloudFormation Deployment Errors**: Check the stack events in the CloudFormation console for detailed error messages.
- **Terraform Errors**: Run `terraform plan` to see what changes Terraform would make, and look for any errors or warnings.
- **AWS CLI Errors**: Ensure your AWS CLI is properly configured with the correct credentials and region.

## Cleanup

To clean up resources created in this lab, you can:

1. Delete CloudFormation stacks:
   ```bash
   aws cloudformation delete-stack --stack-name secure-vpc
   aws cloudformation delete-stack --stack-name security-baseline
   # Continue for all stacks created in this lab
   ```

2. Remove Terraform resources:
   ```bash
   cd labs/lab-3-security-automation-iac/code/terraform
   terraform destroy
   ```

## Next Steps

For more advanced tasks and challenges, see [Challenges](challenges.md) and [Open Challenges](open-challenges.md). 