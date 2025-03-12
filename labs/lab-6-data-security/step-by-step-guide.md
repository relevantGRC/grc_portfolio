# Lab 6: Data Security - Step-by-Step Guide

This guide will walk you through implementing comprehensive data security controls in AWS. Follow each module in sequence to build a complete data security solution.

## Prerequisites

Before starting, ensure you have:

- An AWS account with administrative access
- AWS CLI installed and configured
- Basic understanding of AWS services (S3, RDS, DynamoDB, KMS)

## Module 1: Encryption Foundations

In this module, you'll set up AWS KMS keys and implement encryption for various data storage services.

### Step 1.1: Create KMS Customer Managed Keys

1. Navigate to the AWS KMS console at https://console.aws.amazon.com/kms
2. Click "Create key"
3. Choose "Symmetric" key type and click "Next"
4. Enter an alias for your S3 encryption key (e.g., `data-security-s3-key`)
5. Add a description: "KMS key for S3 bucket encryption in Lab 6"
6. Add tags:
   - Key: `Purpose`, Value: `DataSecurity`
   - Key: `Lab`, Value: `Lab6`
7. Click "Next"
8. For key administrators, select your IAM user or role and click "Next"
9. For key usage permissions, select your IAM user or role and click "Next"
10. Review the settings and click "Finish"
11. Repeat steps 2-10 to create two more keys:
    - One for RDS with alias `data-security-rds-key`
    - One for DynamoDB with alias `data-security-dynamodb-key`

### Step 1.2: Enable Key Rotation

1. In the KMS console, select each key you created
2. Under "Key rotation", click "Edit"
3. Enable automatic key rotation and click "Save"

### Step 1.3: Create an Encrypted S3 Bucket

1. Navigate to the S3 console at https://console.aws.amazon.com/s3
2. Click "Create bucket"
3. Enter a globally unique bucket name: `data-security-lab-[your-initials]-[random-number]`
4. Choose your preferred region
5. Under "Default encryption", select "Enable"
6. Choose "AWS Key Management Service key (SSE-KMS)"
7. Select the S3 KMS key you created earlier
8. Under "Block Public Access settings for this bucket", ensure all options are checked
9. Add tags:
   - Key: `Purpose`, Value: `DataSecurity`
   - Key: `Lab`, Value: `Lab6`
   - Key: `DataClassification`, Value: `Confidential`
10. Click "Create bucket"

### Step 1.4: Create an Encrypted RDS Database

1. Navigate to the RDS console at https://console.aws.amazon.com/rds
2. Click "Create database"
3. Choose "Standard create"
4. Select "MySQL" as the engine type
5. Choose "Free tier" for Template
6. Under "Settings":
   - Enter `data-security-db` for DB instance identifier
   - Set a master username and password (remember these credentials)
7. Under "Storage":
   - Enable storage autoscaling
   - Check "Enable encryption"
   - Select the RDS KMS key you created earlier
8. Under "Connectivity":
   - Choose your default VPC
   - Set "Public access" to "No"
9. Under "Additional configuration":
   - Enter `securitylab` for Initial database name
   - Enable automated backups with 7 days retention
   - Enable encryption of automated backups
10. Add tags:
    - Key: `Purpose`, Value: `DataSecurity`
    - Key: `Lab`, Value: `Lab6`
    - Key: `DataClassification`, Value: `Restricted`
11. Click "Create database"

### Step 1.5: Create an Encrypted DynamoDB Table

1. Navigate to the DynamoDB console at https://console.aws.amazon.com/dynamodb
2. Click "Create table"
3. Enter `DataSecurityTable` for Table name
4. Enter `id` for Partition key and select "String" type
5. Under "Table settings", select "Customize settings"
6. Under "Encryption at rest", select "AWS KMS key"
7. Choose the DynamoDB KMS key you created earlier
8. Add tags:
   - Key: `Purpose`, Value: `DataSecurity`
   - Key: `Lab`, Value: `Lab6`
   - Key: `DataClassification`, Value: `Sensitive`
9. Click "Create table"

## Module 2: Data Classification

In this module, you'll implement data classification using tags and AWS Macie.

### Step 2.1: Define Data Classification Levels

1. Create a document in your S3 bucket that defines your data classification levels:
   ```bash
   echo '{
     "classifications": [
       {
         "level": "Public",
         "description": "Data that can be freely shared"
       },
       {
         "level": "Internal",
         "description": "Data for internal use only"
       },
       {
         "level": "Sensitive",
         "description": "Data that requires protection"
       },
       {
         "level": "Confidential",
         "description": "Highly sensitive data"
       },
       {
         "level": "Restricted",
         "description": "Most sensitive data with strict access controls"
       }
     ]
   }' > classification.json
   
   aws s3 cp classification.json s3://data-security-lab-[your-initials]-[random-number]/
   ```

### Step 2.2: Create Sample Data with Different Classifications

1. Create sample data files with different classifications:
   ```bash
   # Public data
   echo "This is public information that can be freely shared." > public-data.txt
   
   # Internal data
   echo "This is internal information for company use only." > internal-data.txt
   
   # Sensitive data
   echo "This document contains sensitive information including credit card number 4111-1111-1111-1111." > sensitive-data.txt
   
   # Confidential data
   echo "CONFIDENTIAL: This document contains trade secrets and proprietary information." > confidential-data.txt
   
   # Restricted data
   echo "RESTRICTED: This document contains PII including SSN 123-45-6789 and DOB 01/01/1980." > restricted-data.txt
   ```

2. Upload these files to your S3 bucket with appropriate tags:
   ```bash
   # Upload with appropriate tags
   aws s3 cp public-data.txt s3://data-security-lab-[your-initials]-[random-number]/ --tagging "DataClassification=Public"
   
   aws s3 cp internal-data.txt s3://data-security-lab-[your-initials]-[random-number]/ --tagging "DataClassification=Internal"
   
   aws s3 cp sensitive-data.txt s3://data-security-lab-[your-initials]-[random-number]/ --tagging "DataClassification=Sensitive"
   
   aws s3 cp confidential-data.txt s3://data-security-lab-[your-initials]-[random-number]/ --tagging "DataClassification=Confidential"
   
   aws s3 cp restricted-data.txt s3://data-security-lab-[your-initials]-[random-number]/ --tagging "DataClassification=Restricted"
   ```

### Step 2.3: Set Up AWS Macie for Sensitive Data Discovery

1. Navigate to the AWS Macie console at https://console.aws.amazon.com/macie
2. If Macie is not enabled, click "Get started" and then "Enable Macie"
3. In the Macie console, go to "S3 buckets"
4. Find your bucket in the list and select it
5. Click "Create job"
6. Choose "One-time job" and click "Next"
7. Enter `DataSecurityLabMacieJob` for Job name
8. Under "S3 buckets", confirm your bucket is selected
9. Click "Next"
10. Keep the default managed data identifiers and click "Next"
11. Under "Schedule", confirm "One-time job" is selected
12. Click "Next", review the settings, and click "Submit"

### Step 2.4: Review Macie Findings

1. After the Macie job completes, go to "Findings" in the Macie console
2. Review any sensitive data findings
3. Note how Macie automatically identifies sensitive data like credit card numbers and SSNs

## Module 3: Secure Access Patterns

In this module, you'll implement secure access patterns for your data stores.

### Step 3.1: Create IAM Policies Based on Data Classification

1. Navigate to the IAM console at https://console.aws.amazon.com/iam
2. Click "Policies" and then "Create policy"
3. Switch to the JSON editor and paste the following policy:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "AllowPublicDataAccess",
         "Effect": "Allow",
         "Action": [
           "s3:GetObject",
           "s3:ListBucket"
         ],
         "Resource": [
           "arn:aws:s3:::data-security-lab-[your-initials]-[random-number]",
           "arn:aws:s3:::data-security-lab-[your-initials]-[random-number]/*"
         ],
         "Condition": {
           "StringEquals": {
             "s3:ExistingObjectTag/DataClassification": "Public"
           }
         }
       }
     ]
   }
   ```
4. Click "Next", name the policy `PublicDataAccessPolicy`, and click "Create policy"
5. Repeat steps 2-4 to create policies for each classification level, adjusting the condition and permissions accordingly:
   - `InternalDataAccessPolicy`: Allow read for Internal, Public
   - `SensitiveDataAccessPolicy`: Allow read for Sensitive, Internal, Public
   - `ConfidentialDataAccessPolicy`: Allow read for Confidential, Sensitive, Internal, Public
   - `RestrictedDataAccessPolicy`: Allow read for all classifications

### Step 3.2: Create IAM Roles for Different Access Levels

1. In the IAM console, click "Roles" and then "Create role"
2. Select "AWS service" as the trusted entity and "EC2" as the service
3. Click "Next"
4. Search for and select the `PublicDataAccessPolicy` you created
5. Click "Next", name the role `PublicDataAccessRole`, and click "Create role"
6. Repeat steps 1-5 to create roles for each classification level, attaching the corresponding policies

### Step 3.3: Implement S3 Bucket Policy for Encryption in Transit

1. Navigate to the S3 console and select your bucket
2. Go to "Permissions" and scroll down to "Bucket policy"
3. Click "Edit" and paste the following policy (replace the bucket name):
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "DenyInsecureTransport",
         "Effect": "Deny",
         "Principal": "*",
         "Action": "s3:*",
         "Resource": [
           "arn:aws:s3:::data-security-lab-[your-initials]-[random-number]",
           "arn:aws:s3:::data-security-lab-[your-initials]-[random-number]/*"
         ],
         "Condition": {
           "Bool": {
             "aws:SecureTransport": "false"
           }
         }
       }
     ]
   }
   ```
4. Click "Save changes"

### Step 3.4: Set Up VPC Endpoint for S3

1. Navigate to the VPC console at https://console.aws.amazon.com/vpc
2. In the left navigation pane, click "Endpoints"
3. Click "Create endpoint"
4. Select "AWS services" for Service category
5. Search for "S3" and select the S3 Gateway endpoint
6. Select your VPC
7. Under "Route tables", select all route tables for your VPC
8. Under "Policy", select "Custom" and paste the following policy:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "AllowAll",
         "Effect": "Allow",
         "Principal": "*",
         "Action": "s3:*",
         "Resource": "*"
       }
     ]
   }
   ```
9. Add tags:
   - Key: `Purpose`, Value: `DataSecurity`
   - Key: `Lab`, Value: `Lab6`
10. Click "Create endpoint"

## Module 4: Data Access Monitoring

In this module, you'll set up monitoring for data access events.

### Step 4.1: Enable CloudTrail Data Events for S3

1. Navigate to the CloudTrail console at https://console.aws.amazon.com/cloudtrail
2. Click "Trails" in the left navigation pane
3. Click "Create trail"
4. Enter `DataSecurityTrail` for Trail name
5. Under "Storage location", create a new S3 bucket or use an existing one
6. Under "Log events", select "All events"
7. Under "Data events", select "Data events" and then "S3"
8. Choose "All current and future S3 buckets" or specify your bucket
9. Ensure both "Read" and "Write" are selected
10. Click "Next", review the settings, and click "Create trail"

### Step 4.2: Create CloudWatch Alarms for Sensitive Data Access

1. Navigate to the CloudWatch console at https://console.aws.amazon.com/cloudwatch
2. Click "Alarms" in the left navigation pane, then "All alarms"
3. Click "Create alarm"
4. Click "Select metric"
5. Choose "CloudTrail" > "By Trail Name"
6. Select the metric for your trail and click "Select metric"
7. Under "Conditions", choose "Greater/Equal" and enter `1` for the threshold
8. Click "Next"
9. Under "Notification", create a new SNS topic or use an existing one
10. Enter your email address for notifications and click "Create topic"
11. Click "Next"
12. Enter `SensitiveDataAccessAlarm` for Alarm name
13. Click "Next", review the settings, and click "Create alarm"
14. Confirm the subscription in the email you receive

### Step 4.3: Create a CloudWatch Dashboard for Data Security

1. In the CloudWatch console, click "Dashboards" in the left navigation pane
2. Click "Create dashboard"
3. Enter `DataSecurityDashboard` for Dashboard name and click "Create dashboard"
4. Add widgets to your dashboard:
   - Add a "Line" widget for CloudTrail events
   - Add a "Text" widget with information about your data security setup
   - Add an "Alarm Status" widget showing your alarms
5. Click "Save dashboard"

## Module 5: Automated Remediation

In this module, you'll implement automated remediation for data security violations.

### Step 5.1: Create a Lambda Function for S3 Encryption Remediation

1. Navigate to the Lambda console at https://console.aws.amazon.com/lambda
2. Click "Create function"
3. Choose "Author from scratch"
4. Enter `S3EncryptionRemediationFunction` for Function name
5. Choose "Python 3.9" for Runtime
6. Under "Permissions", choose "Create a new role with basic Lambda permissions"
7. Click "Create function"
8. In the function code editor, replace the code with:
   ```python
   import boto3
   import json
   import os
   
   s3_client = boto3.client('s3')
   kms_key_id = os.environ['KMS_KEY_ID']
   
   def lambda_handler(event, context):
       print(f"Received event: {json.dumps(event)}")
       
       # Extract bucket and object information from the event
       bucket_name = event['detail']['requestParameters']['bucketName']
       object_key = event['detail']['requestParameters']['key']
       
       try:
           # Get the object's current encryption status
           object_info = s3_client.head_object(Bucket=bucket_name, Key=object_key)
           
           # Check if the object is encrypted with the correct KMS key
           if 'ServerSideEncryption' not in object_info or object_info['ServerSideEncryption'] != 'aws:kms' or ('SSEKMSKeyId' not in object_info or kms_key_id not in object_info['SSEKMSKeyId']):
               print(f"Object {object_key} in bucket {bucket_name} is not properly encrypted. Remediating...")
               
               # Copy the object back to itself with proper encryption
               s3_client.copy_object(
                   Bucket=bucket_name,
                   Key=object_key,
                   CopySource={'Bucket': bucket_name, 'Key': object_key},
                   ServerSideEncryption='aws:kms',
                   SSEKMSKeyId=kms_key_id
               )
               
               print(f"Successfully remediated encryption for {object_key} in bucket {bucket_name}")
               return {
                   'statusCode': 200,
                   'body': json.dumps('Remediation successful')
               }
           else:
               print(f"Object {object_key} in bucket {bucket_name} is already properly encrypted")
               return {
                   'statusCode': 200,
                   'body': json.dumps('No remediation needed')
               }
       except Exception as e:
           print(f"Error: {str(e)}")
           return {
               'statusCode': 500,
               'body': json.dumps(f'Error: {str(e)}')
           }
   ```
9. Under "Configuration" > "Environment variables", add a variable:
   - Key: `KMS_KEY_ID`
   - Value: [Your S3 KMS key ARN]
10. Under "Configuration" > "Permissions", click on the role name
11. In the IAM console, click "Add permissions" > "Attach policies"
12. Search for and attach the `AmazonS3FullAccess` policy
13. Return to the Lambda function and click "Save"

### Step 5.2: Create an EventBridge Rule to Trigger the Lambda Function

1. Navigate to the EventBridge console at https://console.aws.amazon.com/events
2. Click "Rules" in the left navigation pane, then "Create rule"
3. Enter `S3EncryptionRemediationRule` for Name
4. Under "Define pattern", choose "Event pattern"
5. Choose "Pre-defined pattern by service"
6. Select "AWS services" for Service provider
7. Select "Simple Storage Service (S3)" for Service name
8. Select "Object-level operations" for Event type
9. Select "PutObject" and "CompleteMultipartUpload" for Specific operations
10. Under "Select targets", choose "Lambda function" and select your `S3EncryptionRemediationFunction`
11. Click "Create"

### Step 5.3: Test the Automated Remediation

1. Create a test file without encryption:
   ```bash
   echo "This is a test file" > test-unencrypted.txt
   ```

2. Upload it to your S3 bucket without encryption:
   ```bash
   aws s3 cp test-unencrypted.txt s3://data-security-lab-[your-initials]-[random-number]/ --no-server-side-encryption
   ```

3. Check the Lambda function logs in CloudWatch to see if the remediation was triggered
4. Verify the object's encryption status in the S3 console

## Cleanup

To avoid ongoing charges, delete all resources created in this lab:

1. Delete all objects in your S3 bucket:
   ```bash
   aws s3 rm s3://data-security-lab-[your-initials]-[random-number]/ --recursive
   ```

2. Delete the S3 bucket:
   ```bash
   aws s3 rb s3://data-security-lab-[your-initials]-[random-number]/
   ```

3. Delete the RDS database:
   - Navigate to the RDS console
   - Select your database
   - Click "Actions" > "Delete"
   - Uncheck "Create final snapshot" and check "I acknowledge..."
   - Type "delete me" in the confirmation field and click "Delete"

4. Delete the DynamoDB table:
   - Navigate to the DynamoDB console
   - Select your table
   - Click "Delete"
   - Confirm the deletion

5. Delete the Lambda function:
   - Navigate to the Lambda console
   - Select your function
   - Click "Actions" > "Delete"
   - Confirm the deletion

6. Delete the CloudWatch alarm and dashboard:
   - Navigate to the CloudWatch console
   - Delete the alarm and dashboard you created

7. Delete the CloudTrail trail:
   - Navigate to the CloudTrail console
   - Select your trail
   - Click "Delete"
   - Confirm the deletion

8. Delete the KMS keys:
   - Navigate to the KMS console
   - For each key, click "Schedule key deletion"
   - Choose the minimum waiting period (7 days)
   - Confirm the deletion

9. Delete the IAM policies and roles:
   - Navigate to the IAM console
   - Delete the policies and roles you created

10. Disable Macie:
    - Navigate to the Macie console
    - Go to "Settings"
    - Click "Disable Macie"
    - Confirm the action

## Conclusion

Congratulations! You have successfully implemented comprehensive data security controls in AWS, including:

- Encryption for data at rest using AWS KMS
- Data classification using tags and AWS Macie
- Secure access patterns with IAM policies and S3 bucket policies
- Data access monitoring with CloudTrail and CloudWatch
- Automated remediation for security violations

These controls help ensure your data is protected according to its sensitivity level and comply with security best practices and regulatory requirements. 