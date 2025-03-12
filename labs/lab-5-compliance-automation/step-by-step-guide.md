# Lab 5: Compliance Automation - Step-by-Step Guide

This guide provides detailed instructions for implementing an automated compliance solution in AWS. You'll use various AWS services to set up continuous compliance monitoring, automated remediation, and comprehensive reporting.

## Prerequisites

Before you begin, ensure you have:

1. An AWS account with administrative access
2. AWS CLI installed and configured
3. A terminal or command-line interface
4. Basic knowledge of AWS services, especially AWS Config
5. Completed Labs 1-4 or have equivalent knowledge

## Module 1: Compliance as Code Foundations

In this module, you'll set up the foundational components for your compliance automation solution.

### Step 1: Set up AWS Config

1. **Configure AWS Config through the AWS Console**:
   
   a. Navigate to the AWS Config console
   
   b. Click on "Get started" or "Settings" depending on whether Config has been set up before
   
   c. In the settings page, configure the following:
   - **Recording all resources**: Select "Record all resources supported in this region"
   - **Amazon S3 bucket**: Choose "Create a bucket" to store configuration history and snapshots
   - **SNS topic**: Choose "Create a topic" for compliance notifications
   - **IAM role**: Choose "Create AWS Config service-linked role"
   
   d. Click "Next" and then "Confirm"

2. **Configure AWS Config using AWS CLI**:

   ```bash
   # Create an S3 bucket for AWS Config
   aws s3 mb s3://compliance-config-recordings-ACCOUNT_ID

   # Enable S3 bucket versioning
   aws s3api put-bucket-versioning --bucket compliance-config-recordings-ACCOUNT_ID --versioning-configuration Status=Enabled

   # Create an IAM role for AWS Config
   aws iam create-role --role-name ConfigServiceRole --assume-role-policy-document file://code/config-assume-role.json

   # Attach policy to the IAM role
   aws iam attach-role-policy --role-name ConfigServiceRole --policy-arn arn:aws:iam::aws:policy/service-role/AWS_ConfigRole

   # Set up AWS Config
   aws configservice put-configuration-recorder --configuration-recorder name=default,roleARN=arn:aws:iam::ACCOUNT_ID:role/ConfigServiceRole --recording-group allSupported=true,includeGlobalResources=true

   # Create an S3 bucket delivery channel
   aws configservice put-delivery-channel --delivery-channel name=default,s3BucketName=compliance-config-recordings-ACCOUNT_ID,configSnapshotDeliveryProperties="{\"deliveryFrequency\":\"Six_Hours\"}"

   # Start the configuration recorder
   aws configservice start-configuration-recorder --configuration-recorder-name default
   ```

### Step 2: Create a Compliance Evidence Bucket

1. **Create an S3 bucket to store compliance evidence**:

   ```bash
   # Create an S3 bucket for compliance evidence
   aws s3 mb s3://compliance-evidence-ACCOUNT_ID

   # Enable versioning on the bucket
   aws s3api put-bucket-versioning --bucket compliance-evidence-ACCOUNT_ID --versioning-configuration Status=Enabled

   # Enable default encryption for the bucket
   aws s3api put-bucket-encryption --bucket compliance-evidence-ACCOUNT_ID --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'

   # Block public access to the bucket
   aws s3api put-public-access-block --bucket compliance-evidence-ACCOUNT_ID --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
   ```

### Step 3: Implement Baseline AWS Config Rules

1. **Deploy managed AWS Config rules for essential security controls**:

   ```bash
   # Deploy AWS Config Rules
   aws configservice put-config-rule --config-rule file://code/cloudformation/config-rules/iam-password-policy.json
   aws configservice put-config-rule --config-rule file://code/cloudformation/config-rules/root-mfa-enabled.json
   aws configservice put-config-rule --config-rule file://code/cloudformation/config-rules/encrypted-volumes.json
   aws configservice put-config-rule --config-rule file://code/cloudformation/config-rules/s3-bucket-public-access.json
   aws configservice put-config-rule --config-rule file://code/cloudformation/config-rules/restricted-ssh.json
   ```

2. **Deploy the Config rules using CloudFormation**:

   ```bash
   aws cloudformation create-stack --stack-name compliance-baseline-rules --template-body file://code/cloudformation/config-rules-stack.yaml --parameters ParameterKey=NotificationEmail,ParameterValue=your-email@example.com --capabilities CAPABILITY_IAM
   ```

### Step 4: Set up Compliance Notifications

1. **Create SNS topic for compliance notifications**:

   ```bash
   # Create an SNS topic
   aws sns create-topic --name compliance-notifications

   # Subscribe your email to the topic
   aws sns subscribe --topic-arn arn:aws:sns:REGION:ACCOUNT_ID:compliance-notifications --protocol email --notification-endpoint your-email@example.com
   ```

2. **Configure EventBridge rules to capture compliance events**:

   ```bash
   # Create EventBridge rule for AWS Config compliance changes
   aws events put-rule --name ConfigComplianceChangeRule --event-pattern '{
     "source": ["aws.config"],
     "detail-type": ["Config Rules Compliance Change"]
   }'

   # Set the compliance notification SNS topic as the target
   aws events put-targets --rule ConfigComplianceChangeRule --targets 'Id"="1","Arn"="arn:aws:sns:REGION:ACCOUNT_ID:compliance-notifications"'
   ```

## Module 2: Custom Compliance Rules

In this module, you'll develop and implement custom compliance rules using AWS Lambda and AWS Config.

### Step 1: Create a Custom Config Rule for Resource Tagging

1. **Create an IAM role for the Lambda function**:

   ```bash
   # Create IAM role for Lambda
   aws iam create-role --role-name LambdaConfigRuleRole --assume-role-policy-document file://code/scripts/lambda-functions/lambda-assume-role.json

   # Attach policies to the role
   aws iam attach-role-policy --role-name LambdaConfigRuleRole --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
   aws iam attach-role-policy --role-name LambdaConfigRuleRole --policy-arn arn:aws:iam::aws:policy/service-role/AWSConfigRulesExecutionRole
   ```

2. **Create a Lambda function for tag compliance**:

   a. Create a deployment package:
   ```bash
   cd code/scripts/lambda-functions
   zip required-tags-function.zip required-tags.py
   ```

   b. Deploy the Lambda function:
   ```bash
   aws lambda create-function \
     --function-name RequiredTagsEvaluator \
     --runtime python3.9 \
     --role arn:aws:iam::ACCOUNT_ID:role/LambdaConfigRuleRole \
     --handler required-tags.lambda_handler \
     --zip-file fileb://required-tags-function.zip
   ```

3. **Create the custom AWS Config rule**:

   ```bash
   # Create a custom Config rule linked to the Lambda function
   aws configservice put-config-rule --config-rule file://code/cloudformation/config-rules/required-tags-rule.json
   ```

### Step 2: Create a Custom Data Protection Compliance Rule

1. **Create a Lambda function for S3 encryption compliance**:

   a. Create a deployment package:
   ```bash
   cd code/scripts/lambda-functions
   zip s3-encryption-function.zip s3-encryption.py
   ```

   b. Deploy the Lambda function:
   ```bash
   aws lambda create-function \
     --function-name S3EncryptionEvaluator \
     --runtime python3.9 \
     --role arn:aws:iam::ACCOUNT_ID:role/LambdaConfigRuleRole \
     --handler s3-encryption.lambda_handler \
     --zip-file fileb://s3-encryption-function.zip
   ```

2. **Create the custom AWS Config rule**:

   ```bash
   # Create a custom Config rule linked to the Lambda function
   aws configservice put-config-rule --config-rule file://code/cloudformation/config-rules/s3-encryption-rule.json
   ```

### Step 3: Create a Custom Security Boundary Rule

1. **Create a Lambda function to check security group boundaries**:

   a. Create a deployment package:
   ```bash
   cd code/scripts/lambda-functions
   zip security-group-boundary-function.zip security-group-boundary.py
   ```

   b. Deploy the Lambda function:
   ```bash
   aws lambda create-function \
     --function-name SecurityGroupBoundaryEvaluator \
     --runtime python3.9 \
     --role arn:aws:iam::ACCOUNT_ID:role/LambdaConfigRuleRole \
     --handler security-group-boundary.lambda_handler \
     --zip-file fileb://security-group-boundary-function.zip
   ```

2. **Create the custom AWS Config rule**:

   ```bash
   # Create a custom Config rule linked to the Lambda function
   aws configservice put-config-rule --config-rule file://code/cloudformation/config-rules/security-group-boundary-rule.json
   ```

## Module 3: Automated Remediation

In this module, you'll implement automated remediation for compliance violations.

### Step 1: Create Remediation for S3 Bucket Policy Violations

1. **Create a Lambda function for S3 bucket policy remediation**:

   a. Create a deployment package:
   ```bash
   cd code/scripts/remediation
   zip s3-remediation-function.zip s3-policy-remediation.py
   ```

   b. Deploy the Lambda function:
   ```bash
   aws lambda create-function \
     --function-name S3PolicyRemediator \
     --runtime python3.9 \
     --role arn:aws:iam::ACCOUNT_ID:role/LambdaRemediationRole \
     --handler s3-policy-remediation.lambda_handler \
     --zip-file fileb://s3-remediation-function.zip
   ```

2. **Set up AWS Config auto-remediation**:

   ```bash
   # Add remediation configuration to AWS Config rule
   aws configservice put-remediation-configuration --config-rule-name s3-bucket-public-access --remediation-configuration file://code/cloudformation/remediation/s3-public-access-remediation.json
   ```

### Step 2: Implement Security Group Violation Remediation

1. **Create an SSM Automation document for security group remediation**:

   ```bash
   # Create SSM Automation document
   aws ssm create-document \
     --name SecurityGroupRemediation \
     --document-type Automation \
     --content file://code/scripts/remediation/security-group-remediation.yml
   ```

2. **Set up AWS Config auto-remediation**:

   ```bash
   # Add remediation configuration to AWS Config rule
   aws configservice put-remediation-configuration --config-rule-name restricted-ssh --remediation-configuration file://code/cloudformation/remediation/security-group-remediation.json
   ```

### Step 3: Create Encryption Compliance Remediation

1. **Create an SSM Automation document for EBS encryption remediation**:

   ```bash
   # Create SSM Automation document
   aws ssm create-document \
     --name EBSEncryptionRemediation \
     --document-type Automation \
     --content file://code/scripts/remediation/ebs-encryption-remediation.yml
   ```

2. **Set up AWS Config auto-remediation**:

   ```bash
   # Add remediation configuration to AWS Config rule
   aws configservice put-remediation-configuration --config-rule-name encrypted-volumes --remediation-configuration file://code/cloudformation/remediation/ebs-encryption-remediation.json
   ```

### Step 4: Implement Remediation Logging

1. **Create a Lambda function to log remediation actions**:

   a. Create a deployment package:
   ```bash
   cd code/scripts/remediation
   zip remediation-logger-function.zip remediation-logger.py
   ```

   b. Deploy the Lambda function:
   ```bash
   aws lambda create-function \
     --function-name RemediationLogger \
     --runtime python3.9 \
     --role arn:aws:iam::ACCOUNT_ID:role/LambdaRemediationLoggerRole \
     --handler remediation-logger.lambda_handler \
     --zip-file fileb://remediation-logger-function.zip
   ```

2. **Create an EventBridge rule to trigger logging**:

   ```bash
   # Create EventBridge rule for remediation actions
   aws events put-rule --name RemediationLoggingRule --event-pattern '{
     "source": ["aws.ssm", "aws.lambda"],
     "detail-type": ["AWS API Call via CloudTrail"],
     "detail": {
       "eventSource": ["ssm.amazonaws.com", "lambda.amazonaws.com"],
       "eventName": ["StartAutomationExecution", "InvokeFunction"]
     }
   }'

   # Set the logging Lambda as the target
   aws events put-targets --rule RemediationLoggingRule --targets 'Id"="1","Arn"="arn:aws:lambda:REGION:ACCOUNT_ID:function:RemediationLogger"'
   ```

## Module 4: Compliance Dashboards and Reporting

In this module, you'll create dashboards and reporting mechanisms for compliance visibility.

### Step 1: Create CloudWatch Dashboards for Compliance Status

1. **Create a CloudWatch dashboard using CloudFormation**:

   ```bash
   # Deploy the CloudWatch dashboard using CloudFormation
   aws cloudformation create-stack --stack-name compliance-dashboard --template-body file://code/cloudformation/compliance-dashboard.yaml
   ```

2. **Add custom metrics for compliance status**:

   ```bash
   # Create a script to publish custom compliance metrics
   cd code/scripts/report-generator
   
   # Run the script to publish initial metrics
   python compliance-metrics.py
   
   # Set up a scheduled event to update metrics daily
   aws events put-rule --name DailyComplianceMetrics --schedule-expression "cron(0 1 * * ? *)"
   aws events put-targets --rule DailyComplianceMetrics --targets 'Id"="1","Arn"="arn:aws:lambda:REGION:ACCOUNT_ID:function:ComplianceMetricsGenerator"'
   ```

### Step 2: Implement Automated Report Generation

1. **Create a Lambda function for generating compliance reports**:

   a. Create a deployment package:
   ```bash
   cd code/scripts/report-generator
   zip report-generator-function.zip report-generator.py
   ```

   b. Deploy the Lambda function:
   ```bash
   aws lambda create-function \
     --function-name ComplianceReportGenerator \
     --runtime python3.9 \
     --role arn:aws:iam::ACCOUNT_ID:role/LambdaReportGeneratorRole \
     --handler report-generator.lambda_handler \
     --zip-file fileb://report-generator-function.zip \
     --timeout 300
   ```

2. **Set up a scheduled event to generate weekly reports**:

   ```bash
   # Create a weekly schedule for report generation
   aws events put-rule --name WeeklyComplianceReport --schedule-expression "cron(0 8 ? * MON *)"
   aws events put-targets --rule WeeklyComplianceReport --targets 'Id"="1","Arn"="arn:aws:lambda:REGION:ACCOUNT_ID:function:ComplianceReportGenerator"'
   ```

### Step 3: Create an Evidence Collection Mechanism

1. **Create a Lambda function for collecting compliance evidence**:

   a. Create a deployment package:
   ```bash
   cd code/scripts/evidence-collector
   zip evidence-collector-function.zip evidence-collector.py
   ```

   b. Deploy the Lambda function:
   ```bash
   aws lambda create-function \
     --function-name ComplianceEvidenceCollector \
     --runtime python3.9 \
     --role arn:aws:iam::ACCOUNT_ID:role/LambdaEvidenceCollectorRole \
     --handler evidence-collector.lambda_handler \
     --zip-file fileb://evidence-collector-function.zip \
     --timeout 300
   ```

2. **Set up a scheduled event for evidence collection**:

   ```bash
   # Create a daily schedule for evidence collection
   aws events put-rule --name DailyEvidenceCollection --schedule-expression "cron(0 2 * * ? *)"
   aws events put-targets --rule DailyEvidenceCollection --targets 'Id"="1","Arn"="arn:aws:lambda:REGION:ACCOUNT_ID:function:ComplianceEvidenceCollector"'
   ```

## Module 5: Compliance Frameworks Implementation

In this module, you'll map AWS Config rules to compliance frameworks and create framework-specific dashboards.

### Step 1: Deploy AWS Config Conformance Packs

1. **Deploy the CIS AWS Foundations Benchmark conformance pack**:

   ```bash
   # Download the CIS conformance pack template
   aws configservice get-conformance-pack-template --template-s3-uri s3://aws-conformance-packs/CIS-1.2/CIS_v1.2_Level1_Conformance-Pack.yaml

   # Deploy the conformance pack
   aws configservice put-conformance-pack --conformance-pack-name CIS-Level1 --template-body file://CIS_v1.2_Level1_Conformance-Pack.yaml
   ```

2. **Deploy the NIST 800-53 conformance pack**:

   ```bash
   # Download the NIST conformance pack template
   aws configservice get-conformance-pack-template --template-s3-uri s3://aws-conformance-packs/Operational-Best-Practices-for-NIST-800-53.yaml

   # Deploy the conformance pack
   aws configservice put-conformance-pack --conformance-pack-name NIST-800-53 --template-body file://Operational-Best-Practices-for-NIST-800-53.yaml
   ```

3. **Deploy the PCI DSS conformance pack**:

   ```bash
   # Download the PCI DSS conformance pack template
   aws configservice get-conformance-pack-template --template-s3-uri s3://aws-conformance-packs/Operational-Best-Practices-for-PCI-DSS.yaml

   # Deploy the conformance pack
   aws configservice put-conformance-pack --conformance-pack-name PCI-DSS --template-body file://Operational-Best-Practices-for-PCI-DSS.yaml
   ```

### Step 2: Create Framework-Specific Dashboards

1. **Deploy framework-specific dashboards using CloudFormation**:

   ```bash
   # Deploy the framework-specific dashboards
   aws cloudformation create-stack --stack-name compliance-framework-dashboards --template-body file://code/cloudformation/framework-dashboards.yaml
   ```

### Step 3: Generate Framework Compliance Reports

1. **Create a Lambda function for generating framework-specific reports**:

   a. Create a deployment package:
   ```bash
   cd code/scripts/report-generator
   zip framework-report-generator-function.zip framework-report-generator.py
   ```

   b. Deploy the Lambda function:
   ```bash
   aws lambda create-function \
     --function-name FrameworkReportGenerator \
     --runtime python3.9 \
     --role arn:aws:iam::ACCOUNT_ID:role/LambdaReportGeneratorRole \
     --handler framework-report-generator.lambda_handler \
     --zip-file fileb://framework-report-generator-function.zip \
     --timeout 300
   ```

2. **Set up a scheduled event to generate monthly framework reports**:

   ```bash
   # Create a monthly schedule for framework report generation
   aws events put-rule --name MonthlyFrameworkReport --schedule-expression "cron(0 8 1 * ? *)"
   aws events put-targets --rule MonthlyFrameworkReport --targets 'Id"="1","Arn"="arn:aws:lambda:REGION:ACCOUNT_ID:function:FrameworkReportGenerator"'
   ```

## Validation

After completing all modules, validate your implementation using the following steps:

1. **Verify AWS Config Setup**:
   - Check that the AWS Config recorder is recording
   - Verify that Config rules are evaluating resources
   - Confirm that the S3 bucket has configuration history items

2. **Test Compliance Rules**:
   - Create a non-compliant resource (e.g., an S3 bucket without required tags)
   - Verify that AWS Config marks it as non-compliant
   - Check that notifications are sent to your SNS topic

3. **Test Automated Remediation**:
   - Create a non-compliant resource that triggers auto-remediation
   - Verify that the remediation action happens automatically
   - Check the remediation logs in your compliance evidence bucket

4. **Verify Dashboards and Reports**:
   - Check the CloudWatch dashboard for compliance metrics
   - Verify that automated reports are generated on schedule
   - Confirm that evidence is collected and stored properly

5. **Test Framework Compliance**:
   - Review the conformance pack compliance status
   - Check the framework-specific dashboards
   - Verify that framework reports are generated correctly

## Cleanup

To avoid ongoing charges, clean up the resources created in this lab:

```bash
# Delete conformance packs
aws configservice delete-conformance-pack --conformance-pack-name CIS-Level1
aws configservice delete-conformance-pack --conformance-pack-name NIST-800-53
aws configservice delete-conformance-pack --conformance-pack-name PCI-DSS

# Delete CloudFormation stacks
aws cloudformation delete-stack --stack-name compliance-baseline-rules
aws cloudformation delete-stack --stack-name compliance-dashboard
aws cloudformation delete-stack --stack-name compliance-framework-dashboards

# Delete Lambda functions
aws lambda delete-function --function-name RequiredTagsEvaluator
aws lambda delete-function --function-name S3EncryptionEvaluator
aws lambda delete-function --function-name SecurityGroupBoundaryEvaluator
aws lambda delete-function --function-name S3PolicyRemediator
aws lambda delete-function --function-name RemediationLogger
aws lambda delete-function --function-name ComplianceReportGenerator
aws lambda delete-function --function-name ComplianceEvidenceCollector
aws lambda delete-function --function-name FrameworkReportGenerator

# Delete SSM documents
aws ssm delete-document --name SecurityGroupRemediation
aws ssm delete-document --name EBSEncryptionRemediation

# Stop AWS Config recorder
aws configservice stop-configuration-recorder --configuration-recorder-name default

# Delete AWS Config resources
aws configservice delete-delivery-channel --delivery-channel-name default
aws configservice delete-configuration-recorder --configuration-recorder-name default

# Delete S3 buckets (empty them first)
aws s3 rm s3://compliance-config-recordings-ACCOUNT_ID --recursive
aws s3 rm s3://compliance-evidence-ACCOUNT_ID --recursive
aws s3api delete-bucket --bucket compliance-config-recordings-ACCOUNT_ID
aws s3api delete-bucket --bucket compliance-evidence-ACCOUNT_ID

# Delete SNS topics
aws sns delete-topic --topic-arn arn:aws:sns:REGION:ACCOUNT_ID:compliance-notifications

# Delete EventBridge rules
aws events remove-targets --rule ConfigComplianceChangeRule --ids 1
aws events delete-rule --name ConfigComplianceChangeRule
aws events remove-targets --rule RemediationLoggingRule --ids 1
aws events delete-rule --name RemediationLoggingRule
aws events remove-targets --rule DailyComplianceMetrics --ids 1
aws events delete-rule --name DailyComplianceMetrics
aws events remove-targets --rule WeeklyComplianceReport --ids 1
aws events delete-rule --name WeeklyComplianceReport
aws events remove-targets --rule DailyEvidenceCollection --ids 1
aws events delete-rule --name DailyEvidenceCollection
aws events remove-targets --rule MonthlyFrameworkReport --ids 1
aws events delete-rule --name MonthlyFrameworkReport
```

## Next Steps

After completing this lab, consider these next steps:

1. Extend the compliance solution to multiple AWS accounts using AWS Organizations
2. Implement additional compliance frameworks specific to your industry
3. Integrate with third-party GRC (Governance, Risk, and Compliance) tools
4. Enhance the reporting capabilities with business intelligence tools
5. Implement continuous improvement processes for your compliance program

Congratulations on completing Lab 5: Compliance Automation! 