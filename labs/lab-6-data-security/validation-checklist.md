# Lab 6: Data Security - Validation Checklist

Use this checklist to verify that you have successfully implemented all the required components of the Data Security lab. Each section corresponds to a module in the step-by-step guide.

## Module 1: Encryption Foundations

### KMS Key Configuration
- [ ] Three KMS customer managed keys have been created:
  - [ ] Key for S3 with alias `data-security-s3-key`
  - [ ] Key for RDS with alias `data-security-rds-key`
  - [ ] Key for DynamoDB with alias `data-security-dynamodb-key`
- [ ] Automatic key rotation is enabled for all three keys
- [ ] Key policies grant appropriate permissions to your IAM user/role

### S3 Bucket Encryption
- [ ] S3 bucket has been created with a unique name
- [ ] Default encryption is enabled using the S3 KMS key
- [ ] All public access is blocked
- [ ] Appropriate tags are applied:
  - [ ] `Purpose: DataSecurity`
  - [ ] `Lab: Lab6`
  - [ ] `DataClassification: Confidential`

### RDS Database Encryption
- [ ] RDS MySQL database has been created
- [ ] Storage encryption is enabled using the RDS KMS key
- [ ] Automated backups are enabled with 7-day retention
- [ ] Public access is disabled
- [ ] Appropriate tags are applied:
  - [ ] `Purpose: DataSecurity`
  - [ ] `Lab: Lab6`
  - [ ] `DataClassification: Restricted`

### DynamoDB Table Encryption
- [ ] DynamoDB table has been created with name `DataSecurityTable`
- [ ] Encryption is enabled using the DynamoDB KMS key
- [ ] Appropriate tags are applied:
  - [ ] `Purpose: DataSecurity`
  - [ ] `Lab: Lab6`
  - [ ] `DataClassification: Sensitive`

## Module 2: Data Classification

### Data Classification Definition
- [ ] Classification document (`classification.json`) has been uploaded to the S3 bucket
- [ ] Document defines 5 classification levels: Public, Internal, Sensitive, Confidential, and Restricted

### Sample Data
- [ ] Five sample data files have been created and uploaded to the S3 bucket:
  - [ ] `public-data.txt` with tag `DataClassification: Public`
  - [ ] `internal-data.txt` with tag `DataClassification: Internal`
  - [ ] `sensitive-data.txt` with tag `DataClassification: Sensitive`
  - [ ] `confidential-data.txt` with tag `DataClassification: Confidential`
  - [ ] `restricted-data.txt` with tag `DataClassification: Restricted`

### AWS Macie Configuration
- [ ] AWS Macie is enabled
- [ ] A Macie job has been created to scan the S3 bucket
- [ ] The job has completed and findings are available
- [ ] Macie has correctly identified sensitive data in the sample files

## Module 3: Secure Access Patterns

### IAM Policies
- [ ] Five IAM policies have been created based on data classification:
  - [ ] `PublicDataAccessPolicy`: Allows access to Public data only
  - [ ] `InternalDataAccessPolicy`: Allows access to Internal and Public data
  - [ ] `SensitiveDataAccessPolicy`: Allows access to Sensitive, Internal, and Public data
  - [ ] `ConfidentialDataAccessPolicy`: Allows access to Confidential, Sensitive, Internal, and Public data
  - [ ] `RestrictedDataAccessPolicy`: Allows access to all classification levels

### IAM Roles
- [ ] Five IAM roles have been created with the corresponding policies:
  - [ ] `PublicDataAccessRole`
  - [ ] `InternalDataAccessRole`
  - [ ] `SensitiveDataAccessRole`
  - [ ] `ConfidentialDataAccessRole`
  - [ ] `RestrictedDataAccessRole`

### S3 Bucket Policy
- [ ] S3 bucket policy is configured to enforce HTTPS (SSL/TLS) for all requests
- [ ] The policy denies access to any request not using secure transport

### VPC Endpoint
- [ ] VPC endpoint for S3 has been created
- [ ] Endpoint is associated with appropriate route tables
- [ ] Endpoint policy allows necessary S3 actions
- [ ] Appropriate tags are applied:
  - [ ] `Purpose: DataSecurity`
  - [ ] `Lab: Lab6`

## Module 4: Data Access Monitoring

### CloudTrail Configuration
- [ ] CloudTrail trail has been created with name `DataSecurityTrail`
- [ ] Trail is configured to log data events for S3
- [ ] Both read and write events are captured

### CloudWatch Alarms
- [ ] CloudWatch alarm has been created for sensitive data access
- [ ] Alarm is configured to trigger when access to sensitive data occurs
- [ ] SNS topic is configured for notifications
- [ ] Email subscription is confirmed

### CloudWatch Dashboard
- [ ] CloudWatch dashboard has been created with name `DataSecurityDashboard`
- [ ] Dashboard includes widgets for:
  - [ ] CloudTrail events
  - [ ] Information about data security setup
  - [ ] Alarm status

## Module 5: Automated Remediation

### Lambda Function
- [ ] Lambda function has been created with name `S3EncryptionRemediationFunction`
- [ ] Function code is implemented to check and remediate encryption
- [ ] Environment variable `KMS_KEY_ID` is set with the S3 KMS key ARN
- [ ] Function has appropriate permissions to access S3 and KMS

### EventBridge Rule
- [ ] EventBridge rule has been created with name `S3EncryptionRemediationRule`
- [ ] Rule is configured to trigger on S3 PutObject and CompleteMultipartUpload events
- [ ] Rule target is set to the Lambda function

### Testing
- [ ] Test file has been uploaded without encryption
- [ ] Lambda function was triggered and executed successfully
- [ ] Object encryption has been remediated
- [ ] Object is now encrypted with the correct KMS key

## Overall Validation

To perform a comprehensive validation of your data security implementation, perform the following tests:

### Access Control Testing
- [ ] Attempt to access files with different classification levels using different IAM roles
  - [ ] `PublicDataAccessRole` can only access `public-data.txt`
  - [ ] `InternalDataAccessRole` can access `public-data.txt` and `internal-data.txt`
  - [ ] `SensitiveDataAccessRole` can access `public-data.txt`, `internal-data.txt`, and `sensitive-data.txt`
  - [ ] `ConfidentialDataAccessRole` can access all except `restricted-data.txt`
  - [ ] `RestrictedDataAccessPolicy` can access all files

### Encryption Testing
- [ ] Verify S3 bucket default encryption:
  ```bash
  aws s3api get-bucket-encryption --bucket data-security-lab-[your-initials]-[random-number]
  ```
- [ ] Verify RDS encryption:
  ```bash
  aws rds describe-db-instances --db-instance-identifier data-security-db --query "DBInstances[0].StorageEncrypted"
  ```
- [ ] Verify DynamoDB encryption:
  ```bash
  aws dynamodb describe-table --table-name DataSecurityTable --query "Table.SSEDescription"
  ```

### Secure Transport Testing
- [ ] Attempt to access S3 bucket using HTTP (should fail):
  ```bash
  curl http://data-security-lab-[your-initials]-[random-number].s3.amazonaws.com/
  ```
- [ ] Access S3 bucket using HTTPS (should succeed):
  ```bash
  curl https://data-security-lab-[your-initials]-[random-number].s3.amazonaws.com/
  ```

### Monitoring Testing
- [ ] Access sensitive data and verify CloudWatch alarm triggers
- [ ] Check CloudTrail logs for the access event
- [ ] Verify SNS notification is received

### Remediation Testing
- [ ] Upload a file without encryption:
  ```bash
  aws s3 cp test-unencrypted.txt s3://data-security-lab-[your-initials]-[random-number]/ --no-server-side-encryption
  ```
- [ ] Verify Lambda function is triggered
- [ ] Check that the file is automatically encrypted with the correct KMS key

## Cleanup Validation

After completing the lab, verify that all resources have been properly cleaned up:

- [ ] S3 bucket and all objects have been deleted
- [ ] RDS database has been deleted
- [ ] DynamoDB table has been deleted
- [ ] Lambda function has been deleted
- [ ] CloudWatch alarm and dashboard have been deleted
- [ ] CloudTrail trail has been deleted
- [ ] KMS keys have been scheduled for deletion
- [ ] IAM policies and roles have been deleted
- [ ] Macie has been disabled

Completing this validation checklist ensures that you have successfully implemented a comprehensive data security solution in AWS that protects data at rest and in transit, implements proper access controls based on data classification, monitors data access, and automatically remediates security violations.