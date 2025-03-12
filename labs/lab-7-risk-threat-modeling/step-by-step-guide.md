# Lab 7: Risk Assessment and Threat Modeling - Step-by-Step Guide

This guide will walk you through implementing a comprehensive risk assessment and threat modeling framework in AWS. Follow each module in sequence to build a complete solution.

## Prerequisites

Before starting, ensure you have:

- An AWS account with administrative access
- AWS CLI installed and configured
- Basic understanding of AWS services and security concepts
- Familiarity with security risk assessment concepts

## Module 1: AWS Threat Modeling Methodology

In this module, you'll establish a structured threat modeling approach for AWS environments.

### Step 1.1: Set Up Threat Modeling Templates

1. Create a DynamoDB table for storing threat modeling data:
   ```bash
   aws dynamodb create-table \
     --table-name ThreatModelingDB \
     --attribute-definitions AttributeName=SystemId,AttributeType=S AttributeName=ThreatId,AttributeType=S \
     --key-schema AttributeName=SystemId,KeyType=HASH AttributeName=ThreatId,KeyType=RANGE \
     --billing-mode PAY_PER_REQUEST \
     --tags Key=Purpose,Value=RiskAssessment Key=Lab,Value=Lab7
   ```

2. Create an S3 bucket for storing threat modeling artifacts:
   ```bash
   aws s3 mb s3://threat-modeling-lab-$(aws sts get-caller-identity --query Account --output text) \
     --region $(aws configure get region)
   ```

3. Enable versioning on the bucket:
   ```bash
   aws s3api put-bucket-versioning \
     --bucket threat-modeling-lab-$(aws sts get-caller-identity --query Account --output text) \
     --versioning-configuration Status=Enabled
   ```

### Step 1.2: Define System Components

1. Create a JSON template for system definition:
   ```bash
   cat > system-definition.json << EOF
   {
     "systemName": "Example Web Application",
     "components": {
       "networking": {
         "vpc": "Primary VPC",
         "subnets": ["Public", "Private", "Database"],
         "securityGroups": ["ALB", "Web", "App", "DB"]
       },
       "compute": {
         "ec2": "Web Servers",
         "ecs": "Application Containers",
         "lambda": "Backend Functions"
       },
       "storage": {
         "s3": "Static Assets",
         "rds": "Customer Data",
         "dynamodb": "Session Data"
       },
       "security": {
         "iam": "Service Roles",
         "kms": "Encryption Keys",
         "waf": "Web Application Firewall"
       }
     }
   }
   EOF

   aws s3 cp system-definition.json s3://threat-modeling-lab-$(aws sts get-caller-identity --query Account --output text)/
   ```

### Step 1.3: Implement STRIDE Analysis

1. Create a Lambda function for STRIDE analysis:
   ```bash
   mkdir -p stride-analysis && cd stride-analysis
   
   cat > lambda_function.py << EOF
   import json
   import boto3
   import os
   from datetime import datetime

   def analyze_stride(component):
       threats = []
       
       # Spoofing analysis
       if 'iam' in component or 'authentication' in component:
           threats.append({
               'category': 'Spoofing',
               'description': f'Identity spoofing in {component}',
               'mitigation': 'Implement MFA and strong authentication'
           })
       
       # Tampering analysis
       if any(x in component for x in ['s3', 'rds', 'dynamodb']):
           threats.append({
               'category': 'Tampering',
               'description': f'Data tampering in {component}',
               'mitigation': 'Implement integrity checks and audit logging'
           })
       
       # Repudiation analysis
       threats.append({
           'category': 'Repudiation',
           'description': f'Action denial in {component}',
           'mitigation': 'Enable CloudTrail and implement secure logging'
       })
       
       # Information disclosure analysis
       if any(x in component for x in ['s3', 'rds', 'secrets']):
           threats.append({
               'category': 'Information_Disclosure',
               'description': f'Data exposure in {component}',
               'mitigation': 'Implement encryption and access controls'
           })
       
       # Denial of service analysis
       if any(x in component for x in ['ec2', 'alb', 'api']):
           threats.append({
               'category': 'Denial_of_Service',
               'description': f'DoS vulnerability in {component}',
               'mitigation': 'Implement AWS Shield and scaling policies'
           })
       
       # Elevation of privilege analysis
       if 'iam' in component or 'role' in component:
           threats.append({
               'category': 'Elevation_of_Privilege',
               'description': f'Privilege escalation in {component}',
               'mitigation': 'Implement least privilege and permission boundaries'
           })
       
       return threats

   def lambda_handler(event, context):
       dynamodb = boto3.resource('dynamodb')
       table = dynamodb.Table(os.environ['THREAT_TABLE'])
       
       system_components = event['components']
       system_id = event['systemId']
       
       for component, details in system_components.items():
           threats = analyze_stride(component)
           
           for threat in threats:
               table.put_item(
                   Item={
                       'SystemId': system_id,
                       'ThreatId': f"{component}-{threat['category']}-{datetime.now().isoformat()}",
                       'Component': component,
                       'Category': threat['category'],
                       'Description': threat['description'],
                       'Mitigation': threat['mitigation'],
                       'Status': 'Open',
                       'CreatedAt': datetime.now().isoformat()
                   }
               )
       
       return {
           'statusCode': 200,
           'body': json.dumps('STRIDE analysis completed')
       }
   EOF
   ```

2. Create a deployment package:
   ```bash
   zip -r stride-analysis.zip lambda_function.py
   ```

3. Create an IAM role for the Lambda function:
   ```bash
   aws iam create-role \
     --role-name StrideAnalysisRole \
     --assume-role-policy-document '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Principal": {
           "Service": "lambda.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }]
     }'
   ```

4. Attach necessary permissions:
   ```bash
   aws iam put-role-policy \
     --role-name StrideAnalysisRole \
     --policy-name StrideAnalysisPolicy \
     --policy-document '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Action": [
           "dynamodb:PutItem",
           "logs:CreateLogGroup",
           "logs:CreateLogStream",
           "logs:PutLogEvents"
         ],
         "Resource": "*"
       }]
     }'
   ```

5. Deploy the Lambda function:
   ```bash
   aws lambda create-function \
     --function-name StrideAnalysis \
     --runtime python3.9 \
     --handler lambda_function.lambda_handler \
     --role $(aws iam get-role --role-name StrideAnalysisRole --query Role.Arn --output text) \
     --zip-file fileb://stride-analysis.zip \
     --environment Variables={THREAT_TABLE=ThreatModelingDB}
   ```

### Step 1.4: Implement DREAD Scoring

1. Create a Lambda function for DREAD scoring:
   ```bash
   mkdir -p dread-scoring && cd dread-scoring
   
   cat > lambda_function.py << EOF
   import json
   import boto3
   import os
   from datetime import datetime

   def calculate_dread_score(threat):
       scores = {
           'Damage': 0,
           'Reproducibility': 0,
           'Exploitability': 0,
           'Affected_Users': 0,
           'Discoverability': 0
       }
       
       # Damage potential
       if 'data' in threat['description'].lower():
           scores['Damage'] = 3
       elif 'service' in threat['description'].lower():
           scores['Damage'] = 2
       else:
           scores['Damage'] = 1
       
       # Reproducibility
       if 'authentication' in threat['description'].lower():
           scores['Reproducibility'] = 2
       else:
           scores['Reproducibility'] = 1
       
       # Exploitability
       if any(x in threat['description'].lower() for x in ['iam', 'role', 'permission']):
           scores['Exploitability'] = 3
       else:
           scores['Exploitability'] = 2
       
       # Affected users
       if 'all' in threat['description'].lower():
           scores['Affected_Users'] = 3
       else:
           scores['Affected_Users'] = 1
       
       # Discoverability
       if any(x in threat['description'].lower() for x in ['public', 'exposed']):
           scores['Discoverability'] = 3
       else:
           scores['Discoverability'] = 1
       
       total_score = sum(scores.values())
       risk_level = 'High' if total_score > 10 else 'Medium' if total_score > 5 else 'Low'
       
       return {
           'scores': scores,
           'total_score': total_score,
           'risk_level': risk_level
       }

   def lambda_handler(event, context):
       dynamodb = boto3.resource('dynamodb')
       table = dynamodb.Table(os.environ['THREAT_TABLE'])
       
       threat = event['threat']
       system_id = event['systemId']
       threat_id = event['threatId']
       
       dread_score = calculate_dread_score(threat)
       
       table.update_item(
           Key={
               'SystemId': system_id,
               'ThreatId': threat_id
           },
           UpdateExpression='SET DREADScore = :score, RiskLevel = :level',
           ExpressionAttributeValues={
               ':score': dread_score['scores'],
               ':level': dread_score['risk_level']
           }
       )
       
       return {
           'statusCode': 200,
           'body': json.dumps(dread_score)
       }
   EOF
   ```

2. Create a deployment package:
   ```bash
   zip -r dread-scoring.zip lambda_function.py
   ```

3. Create an IAM role for the Lambda function:
   ```bash
   aws iam create-role \
     --role-name DreadScoringRole \
     --assume-role-policy-document '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Principal": {
           "Service": "lambda.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }]
     }'
   ```

4. Attach necessary permissions:
   ```bash
   aws iam put-role-policy \
     --role-name DreadScoringRole \
     --policy-name DreadScoringPolicy \
     --policy-document '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Action": [
           "dynamodb:UpdateItem",
           "logs:CreateLogGroup",
           "logs:CreateLogStream",
           "logs:PutLogEvents"
         ],
         "Resource": "*"
       }]
     }'
   ```

5. Deploy the Lambda function:
   ```bash
   aws lambda create-function \
     --function-name DreadScoring \
     --runtime python3.9 \
     --handler lambda_function.lambda_handler \
     --role $(aws iam get-role --role-name DreadScoringRole --query Role.Arn --output text) \
     --zip-file fileb://dread-scoring.zip \
     --environment Variables={THREAT_TABLE=ThreatModelingDB}
   ```

## Module 2: Service-Specific Risk Assessments

In this module, you'll implement risk assessments for specific AWS services.

### Step 2.1: Create Risk Assessment Templates

1. Create templates for different service types:
   ```bash
   mkdir -p risk-templates
   
   # S3 Risk Assessment Template
   cat > risk-templates/s3-assessment.json << EOF
   {
     "serviceType": "S3",
     "riskCategories": {
       "access_control": {
         "checks": [
           "bucket_public_access",
           "bucket_policy_review",
           "encryption_configuration",
           "logging_enabled",
           "versioning_enabled"
         ]
       },
       "data_protection": {
         "checks": [
           "encryption_at_rest",
           "encryption_in_transit",
           "lifecycle_policies",
           "cross_region_replication"
         ]
       },
       "compliance": {
         "checks": [
           "tag_compliance",
           "data_classification",
           "retention_policies"
         ]
       }
     }
   }
   EOF

   # RDS Risk Assessment Template
   cat > risk-templates/rds-assessment.json << EOF
   {
     "serviceType": "RDS",
     "riskCategories": {
       "access_control": {
         "checks": [
           "network_access",
           "iam_authentication",
           "security_groups"
         ]
       },
       "data_protection": {
         "checks": [
           "encryption_at_rest",
           "backup_configuration",
           "multi_az_setup"
         ]
       },
       "compliance": {
         "checks": [
           "parameter_group_settings",
           "logging_configuration",
           "patch_management"
         ]
       }
     }
   }
   EOF

   # Upload templates to S3
   aws s3 cp risk-templates/ s3://threat-modeling-lab-$(aws sts get-caller-identity --query Account --output text)/templates/ --recursive
   ```

### Step 2.2: Create Risk Assessment Lambda Function

1. Create a Lambda function for service risk assessment:
   ```bash
   mkdir -p risk-assessment && cd risk-assessment
   
   cat > lambda_function.py << EOF
   import json
   import boto3
   import os
   from datetime import datetime

   def assess_service(service_type, resource_id):
       # Initialize AWS clients
       s3 = boto3.client('s3')
       rds = boto3.client('rds')
       config = boto3.client('config')
       
       findings = []
       
       if service_type == 'S3':
           try:
               # Check bucket encryption
               encryption = s3.get_bucket_encryption(Bucket=resource_id)
               findings.append({
                   'check': 'encryption_at_rest',
                   'status': 'PASS',
                   'details': 'Bucket encryption is enabled'
               })
           except s3.exceptions.ClientError:
               findings.append({
                   'check': 'encryption_at_rest',
                   'status': 'FAIL',
                   'details': 'Bucket encryption is not enabled'
               })
           
           # Check public access
           public_access = s3.get_public_access_block(Bucket=resource_id)
           if all(public_access['PublicAccessBlockConfiguration'].values()):
               findings.append({
                   'check': 'bucket_public_access',
                   'status': 'PASS',
                   'details': 'Public access is blocked'
               })
           else:
               findings.append({
                   'check': 'bucket_public_access',
                   'status': 'FAIL',
                   'details': 'Public access is not fully blocked'
               })
           
       elif service_type == 'RDS':
           try:
               # Get DB instance details
               db = rds.describe_db_instances(DBInstanceIdentifier=resource_id)['DBInstances'][0]
               
               # Check encryption
               if db['StorageEncrypted']:
                   findings.append({
                       'check': 'encryption_at_rest',
                       'status': 'PASS',
                       'details': 'DB encryption is enabled'
                   })
               else:
                   findings.append({
                       'check': 'encryption_at_rest',
                       'status': 'FAIL',
                       'details': 'DB encryption is not enabled'
                   })
               
               # Check backup configuration
               if db['BackupRetentionPeriod'] > 0:
                   findings.append({
                       'check': 'backup_configuration',
                       'status': 'PASS',
                       'details': f"Backup retention period is {db['BackupRetentionPeriod']} days"
                   })
               else:
                   findings.append({
                       'check': 'backup_configuration',
                       'status': 'FAIL',
                       'details': 'Automated backups are not enabled'
                   })
           except rds.exceptions.DBInstanceNotFoundFault:
               findings.append({
                   'check': 'resource_exists',
                   'status': 'FAIL',
                   'details': 'DB instance not found'
               })
       
       return findings

   def lambda_handler(event, context):
       dynamodb = boto3.resource('dynamodb')
       table = dynamodb.Table(os.environ['ASSESSMENT_TABLE'])
       
       service_type = event['serviceType']
       resource_id = event['resourceId']
       
       findings = assess_service(service_type, resource_id)
       
       # Store assessment results
       assessment_id = f"{service_type}-{resource_id}-{datetime.now().isoformat()}"
       table.put_item(
           Item={
               'AssessmentId': assessment_id,
               'ServiceType': service_type,
               'ResourceId': resource_id,
               'Findings': findings,
               'Timestamp': datetime.now().isoformat(),
               'Status': 'Completed'
           }
       )
       
       return {
           'statusCode': 200,
           'body': json.dumps({
               'assessmentId': assessment_id,
               'findings': findings
           })
       }
   EOF
   ```

2. Create a deployment package:
   ```bash
   zip -r risk-assessment.zip lambda_function.py
   ```

3. Create an IAM role for the Lambda function:
   ```bash
   aws iam create-role \
     --role-name ServiceRiskAssessmentRole \
     --assume-role-policy-document '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Principal": {
           "Service": "lambda.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }]
     }'
   ```

4. Attach necessary permissions:
   ```bash
   aws iam put-role-policy \
     --role-name ServiceRiskAssessmentRole \
     --policy-name ServiceRiskAssessmentPolicy \
     --policy-document '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Action": [
           "s3:GetBucketEncryption",
           "s3:GetPublicAccessBlock",
           "rds:DescribeDBInstances",
           "config:GetResourceConfigHistory",
           "dynamodb:PutItem",
           "logs:CreateLogGroup",
           "logs:CreateLogStream",
           "logs:PutLogEvents"
         ],
         "Resource": "*"
       }]
     }'
   ```

5. Deploy the Lambda function:
   ```bash
   aws lambda create-function \
     --function-name ServiceRiskAssessment \
     --runtime python3.9 \
     --handler lambda_function.lambda_handler \
     --role $(aws iam get-role --role-name ServiceRiskAssessmentRole --query Role.Arn --output text) \
     --zip-file fileb://risk-assessment.zip \
     --environment Variables={ASSESSMENT_TABLE=RiskAssessmentDB}
   ```

## Module 3: AWS Trusted Advisor Integration

In this module, you'll integrate with AWS Trusted Advisor for automated risk identification.

### Step 3.1: Set Up Trusted Advisor Checks

1. Enable Business Support or Enterprise Support to access all Trusted Advisor checks:
   ```bash
   echo "Note: You need Business Support or Enterprise Support to access all Trusted Advisor checks."
   echo "Visit https://console.aws.amazon.com/support/plans to upgrade your support plan if needed."
   ```

2. Create a Lambda function to process Trusted Advisor results:
   ```bash
   mkdir -p trusted-advisor && cd trusted-advisor
   
   cat > lambda_function.py << EOF
   import json
   import boto3
   import os
   from datetime import datetime

   def lambda_handler(event, context):
       support = boto3.client('support')
       dynamodb = boto3.resource('dynamodb')
       table = dynamodb.Table(os.environ['FINDINGS_TABLE'])
       sns = boto3.client('sns')
       
       # Get all Trusted Advisor checks
       checks = support.describe_trusted_advisor_checks(language='en')
       
       high_risk_findings = []
       
       for check in checks['checks']:
           if check['category'] in ['security', 'fault_tolerance']:
               # Get check results
               result = support.describe_trusted_advisor_check_result(
                   checkId=check['id'],
                   language='en'
               )
               
               if result['result']['status'] == 'error':
                   finding = {
                       'checkName': check['name'],
                       'category': check['category'],
                       'status': result['result']['status'],
                       'resourcesSummary': result['result'].get('resourcesSummary', {}),
                       'timestamp': datetime.now().isoformat()
                   }
                   
                   high_risk_findings.append(finding)
                   
                   # Store finding in DynamoDB
                   table.put_item(Item={
                       'FindingId': f"{check['id']}-{datetime.now().isoformat()}",
                       'CheckName': check['name'],
                       'Category': check['category'],
                       'Status': result['result']['status'],
                       'ResourcesSummary': result['result'].get('resourcesSummary', {}),
                       'Timestamp': datetime.now().isoformat()
                   })
       
       # Send notification if high-risk findings exist
       if high_risk_findings:
           sns.publish(
               TopicArn=os.environ['SNS_TOPIC_ARN'],
               Subject='High Risk Trusted Advisor Findings',
               Message=json.dumps(high_risk_findings, indent=2)
           )
       
       return {
           'statusCode': 200,
           'body': json.dumps({
               'highRiskFindings': len(high_risk_findings),
               'findings': high_risk_findings
           })
       }
   EOF
   ```

3. Create a deployment package:
   ```bash
   zip -r trusted-advisor.zip lambda_function.py
   ```

4. Create an IAM role for the Lambda function:
   ```bash
   aws iam create-role \
     --role-name TrustedAdvisorRole \
     --assume-role-policy-document '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Principal": {
           "Service": "lambda.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }]
     }'
   ```

5. Attach necessary permissions:
   ```bash
   aws iam put-role-policy \
     --role-name TrustedAdvisorRole \
     --policy-name TrustedAdvisorPolicy \
     --policy-document '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Action": [
           "support:*",
           "dynamodb:PutItem",
           "sns:Publish",
           "logs:CreateLogGroup",
           "logs:CreateLogStream",
           "logs:PutLogEvents"
         ],
         "Resource": "*"
       }]
     }'
   ```

6. Deploy the Lambda function:
   ```bash
   aws lambda create-function \
     --function-name TrustedAdvisorCheck \
     --runtime python3.9 \
     --handler lambda_function.lambda_handler \
     --role $(aws iam get-role --role-name TrustedAdvisorRole --query Role.Arn --output text) \
     --zip-file fileb://trusted-advisor.zip \
     --environment Variables={
       FINDINGS_TABLE=TrustedAdvisorFindings,
       SNS_TOPIC_ARN=$(aws sns create-topic --name risk-assessment-notifications --query TopicArn --output text)
     }
   ```

### Step 3.2: Schedule Regular Checks

1. Create an EventBridge rule to trigger the Lambda function:
   ```bash
   aws events put-rule \
     --name DailyTrustedAdvisorCheck \
     --schedule-expression "rate(1 day)" \
     --state ENABLED

   aws events put-targets \
     --rule DailyTrustedAdvisorCheck \
     --targets "Id"="1","Arn"="$(aws lambda get-function --function-name TrustedAdvisorCheck --query Configuration.FunctionArn --output text)"
   ```

## Module 4: Vulnerability Prioritization

In this module, you'll implement a vulnerability scoring and prioritization system.

### Step 4.1: Create Vulnerability Scoring System

1. Create a Lambda function for vulnerability scoring:
   ```bash
   mkdir -p vulnerability-scoring && cd vulnerability-scoring
   
   cat > lambda_function.py << EOF
   import json
   import boto3
   import os
   from datetime import datetime

   def calculate_cvss_score(vulnerability):
       # Simplified CVSS scoring
       base_score = 0
       
       # Attack Vector
       if vulnerability.get('attackVector') == 'NETWORK':
           base_score += 3
       elif vulnerability.get('attackVector') == 'ADJACENT':
           base_score += 2
       elif vulnerability.get('attackVector') == 'LOCAL':
           base_score += 1
       
       # Impact
       if vulnerability.get('impact') == 'HIGH':
           base_score += 3
       elif vulnerability.get('impact') == 'MEDIUM':
           base_score += 2
       elif vulnerability.get('impact') == 'LOW':
           base_score += 1
       
       # Exploitability
       if vulnerability.get('exploitability') == 'HIGH':
           base_score += 3
       elif vulnerability.get('exploitability') == 'MEDIUM':
           base_score += 2
       elif vulnerability.get('exploitability') == 'LOW':
           base_score += 1
       
       return base_score

   def calculate_business_impact(vulnerability, business_context):
       impact_score = 0
       
       # Data sensitivity
       if business_context.get('dataSensitivity') == 'HIGH':
           impact_score += 3
       elif business_context.get('dataSensitivity') == 'MEDIUM':
           impact_score += 2
       elif business_context.get('dataSensitivity') == 'LOW':
           impact_score += 1
       
       # Business criticality
       if business_context.get('businessCriticality') == 'HIGH':
           impact_score += 3
       elif business_context.get('businessCriticality') == 'MEDIUM':
           impact_score += 2
       elif business_context.get('businessCriticality') == 'LOW':
           impact_score += 1
       
       return impact_score

   def lambda_handler(event, context):
       dynamodb = boto3.resource('dynamodb')
       table = dynamodb.Table(os.environ['VULNERABILITIES_TABLE'])
       sns = boto3.client('sns')
       
       vulnerability = event['vulnerability']
       business_context = event['businessContext']
       
       # Calculate scores
       cvss_score = calculate_cvss_score(vulnerability)
       business_impact = calculate_business_impact(vulnerability, business_context)
       total_score = cvss_score + business_impact
       
       # Determine risk level
       if total_score >= 10:
           risk_level = 'Critical'
       elif total_score >= 7:
           risk_level = 'High'
       elif total_score >= 4:
           risk_level = 'Medium'
       else:
           risk_level = 'Low'
       
       # Store results
       vulnerability_id = f"VULN-{datetime.now().isoformat()}"
       result = {
           'VulnerabilityId': vulnerability_id,
           'CVSSScore': cvss_score,
           'BusinessImpact': business_impact,
           'TotalScore': total_score,
           'RiskLevel': risk_level,
           'Vulnerability': vulnerability,
           'BusinessContext': business_context,
           'Timestamp': datetime.now().isoformat()
       }
       
       table.put_item(Item=result)
       
       # Send notification for critical and high risks
       if risk_level in ['Critical', 'High']:
           sns.publish(
               TopicArn=os.environ['SNS_TOPIC_ARN'],
               Subject=f'{risk_level} Risk Vulnerability Identified',
               Message=json.dumps(result, indent=2)
           )
       
       return {
           'statusCode': 200,
           'body': json.dumps(result)
       }
   EOF
   ```

2. Create a deployment package:
   ```bash
   zip -r vulnerability-scoring.zip lambda_function.py
   ```

3. Create an IAM role for the Lambda function:
   ```bash
   aws iam create-role \
     --role-name VulnerabilityScoringRole \
     --assume-role-policy-document '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Principal": {
           "Service": "lambda.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }]
     }'
   ```

4. Attach necessary permissions:
   ```bash
   aws iam put-role-policy \
     --role-name VulnerabilityScoringRole \
     --policy-name VulnerabilityScoringPolicy \
     --policy-document '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Action": [
           "dynamodb:PutItem",
           "sns:Publish",
           "logs:CreateLogGroup",
           "logs:CreateLogStream",
           "logs:PutLogEvents"
         ],
         "Resource": "*"
       }]
     }'
   ```

5. Deploy the Lambda function:
   ```bash
   aws lambda create-function \
     --function-name VulnerabilityScoring \
     --runtime python3.9 \
     --handler lambda_function.lambda_handler \
     --role $(aws iam get-role --role-name VulnerabilityScoringRole --query Role.Arn --output text) \
     --zip-file fileb://vulnerability-scoring.zip \
     --environment Variables={
       VULNERABILITIES_TABLE=VulnerabilityScoring,
       SNS_TOPIC_ARN=$(aws sns list-topics --query 'Topics[0].TopicArn' --output text)
     }
   ```

## Module 5: Risk Dashboards and Reporting

In this module, you'll create dashboards and automated reporting for risk visualization.

### Step 5.1: Create CloudWatch Dashboard

1. Create a CloudWatch dashboard:
   ```bash
   aws cloudwatch put-dashboard \
     --dashboard-name RiskAssessmentDashboard \
     --dashboard-body '{
       "widgets": [
         {
           "type": "metric",
           "x": 0,
           "y": 0,
           "width": 12,
           "height": 6,
           "properties": {
             "metrics": [
               ["AWS/Lambda", "Invocations", "FunctionName", "VulnerabilityScoring"],
               ["AWS/Lambda", "Invocations", "FunctionName", "TrustedAdvisorCheck"],
               ["AWS/Lambda", "Invocations", "FunctionName", "ServiceRiskAssessment"]
             ],
             "view": "timeSeries",
             "stacked": false,
             "region": "'$(aws configure get region)'",
             "period": 300,
             "stat": "Sum",
             "title": "Risk Assessment Functions Invocations"
           }
         },
         {
           "type": "metric",
           "x": 12,
           "y": 0,
           "width": 12,
           "height": 6,
           "properties": {
             "metrics": [
               ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "VulnerabilityScoring"],
               ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", "VulnerabilityScoring"]
             ],
             "view": "timeSeries",
             "stacked": false,
             "region": "'$(aws configure get region)'",
             "period": 300,
             "stat": "Sum",
             "title": "Vulnerability Database Usage"
           }
         }
       ]
     }'
   ```

### Step 5.2: Set Up Automated Reporting

1. Create a Lambda function for generating reports:
   ```bash
   mkdir -p risk-reporting && cd risk-reporting
   
   cat > lambda_function.py << EOF
   import json
   import boto3
   import os
   from datetime import datetime, timedelta
   
   def generate_report():
       dynamodb = boto3.resource('dynamodb')
       s3 = boto3.client('s3')
       
       # Get vulnerabilities from the last 24 hours
       vuln_table = dynamodb.Table(os.environ['VULNERABILITIES_TABLE'])
       advisor_table = dynamodb.Table(os.environ['FINDINGS_TABLE'])
       
       yesterday = datetime.now() - timedelta(days=1)
       
       # Compile report data
       report = {
           'generated_at': datetime.now().isoformat(),
           'period': '24 hours',
           'summary': {
               'critical_vulnerabilities': 0,
               'high_vulnerabilities': 0,
               'medium_vulnerabilities': 0,
               'low_vulnerabilities': 0,
               'trusted_advisor_findings': 0
           },
           'vulnerabilities': [],
           'trusted_advisor_findings': []
       }
       
       # Query vulnerabilities
       response = vuln_table.scan()
       for item in response.get('Items', []):
           if item['Timestamp'] >= yesterday.isoformat():
               report['vulnerabilities'].append(item)
               report['summary'][f"{item['RiskLevel'].lower()}_vulnerabilities"] += 1
       
       # Query Trusted Advisor findings
       response = advisor_table.scan()
       for item in response.get('Items', []):
           if item['Timestamp'] >= yesterday.isoformat():
               report['trusted_advisor_findings'].append(item)
               report['summary']['trusted_advisor_findings'] += 1
       
       # Generate report file
       report_json = json.dumps(report, indent=2)
       filename = f"risk-report-{datetime.now().strftime('%Y-%m-%d')}.json"
       
       # Upload to S3
       s3.put_object(
           Bucket=os.environ['REPORTS_BUCKET'],
           Key=f"daily-reports/{filename}",
           Body=report_json,
           ContentType='application/json'
       )
       
       return report
   
   def lambda_handler(event, context):
       report = generate_report()
       
       # Send notification
       sns = boto3.client('sns')
       sns.publish(
           TopicArn=os.environ['SNS_TOPIC_ARN'],
           Subject='Daily Risk Assessment Report',
           Message=json.dumps(report, indent=2)
       )
       
       return {
           'statusCode': 200,
           'body': json.dumps({
               'message': 'Report generated successfully',
               'report': report
           })
       }
   EOF
   ```

2. Create a deployment package:
   ```bash
   zip -r risk-reporting.zip lambda_function.py
   ```

3. Create an IAM role for the Lambda function:
   ```bash
   aws iam create-role \
     --role-name RiskReportingRole \
     --assume-role-policy-document '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Principal": {
           "Service": "lambda.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }]
     }'
   ```

4. Attach necessary permissions:
   ```bash
   aws iam put-role-policy \
     --role-name RiskReportingRole \
     --policy-name RiskReportingPolicy \
     --policy-document '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Action": [
           "dynamodb:Scan",
           "s3:PutObject",
           "sns:Publish",
           "logs:CreateLogGroup",
           "logs:CreateLogStream",
           "logs:PutLogEvents"
         ],
         "Resource": "*"
       }]
     }'
   ```

5. Deploy the Lambda function:
   ```bash
   aws lambda create-function \
     --function-name RiskReporting \
     --runtime python3.9 \
     --handler lambda_function.lambda_handler \
     --role $(aws iam get-role --role-name RiskReportingRole --query Role.Arn --output text) \
     --zip-file fileb://risk-reporting.zip \
     --environment Variables={
       VULNERABILITIES_TABLE=VulnerabilityScoring,
       FINDINGS_TABLE=TrustedAdvisorFindings,
       REPORTS_BUCKET=risk-reports-$(aws sts get-caller-identity --query Account --output text),
       SNS_TOPIC_ARN=$(aws sns list-topics --query 'Topics[0].TopicArn' --output text)
     }
   ```

6. Schedule daily report generation:
   ```bash
   aws events put-rule \
     --name DailyRiskReport \
     --schedule-expression "cron(0 0 * * ? *)" \
     --state ENABLED

   aws events put-targets \
     --rule DailyRiskReport \
     --targets "Id"="1","Arn"="$(aws lambda get-function --function-name RiskReporting --query Configuration.FunctionArn --output text)"
   ```

## Cleanup

To avoid ongoing charges, delete all resources created in this lab:

1. Delete Lambda functions:
   ```bash
   for function in StrideAnalysis DreadScoring ServiceRiskAssessment TrustedAdvisorCheck VulnerabilityScoring RiskReporting; do
     aws lambda delete-function --function-name $function
   done
   ```

2. Delete IAM roles and policies:
   ```bash
   for role in StrideAnalysisRole DreadScoringRole ServiceRiskAssessmentRole TrustedAdvisorRole VulnerabilityScoringRole RiskReportingRole; do
     aws iam delete-role-policy --role-name $role --policy-name ${role}Policy
     aws iam delete-role --role-name $role
   done
   ```

3. Delete DynamoDB tables:
   ```bash
   for table in ThreatModelingDB RiskAssessmentDB TrustedAdvisorFindings VulnerabilityScoring; do
     aws dynamodb delete-table --table-name $table
   done
   ```

4. Delete S3 buckets:
   ```bash
   ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
   aws s3 rm s3://threat-modeling-lab-$ACCOUNT_ID --recursive
   aws s3 rb s3://threat-modeling-lab-$ACCOUNT_ID
   aws s3 rm s3://risk-reports-$ACCOUNT_ID --recursive
   aws s3 rb s3://risk-reports-$ACCOUNT_ID
   ```

5. Delete EventBridge rules:
   ```bash
   aws events remove-targets --rule DailyTrustedAdvisorCheck --ids "1"
   aws events delete-rule --name DailyTrustedAdvisorCheck
   aws events remove-targets --rule DailyRiskReport --ids "1"
   aws events delete-rule --name DailyRiskReport
   ```

6. Delete CloudWatch dashboard:
   ```bash
   aws cloudwatch delete-dashboards --dashboard-names RiskAssessmentDashboard
   ```

7. Delete SNS topics:
   ```bash
   aws sns delete-topic --topic-arn $(aws sns list-topics --query 'Topics[0].TopicArn' --output text)
   ```

## Conclusion

Congratulations! You have successfully implemented a comprehensive risk assessment and threat modeling framework in AWS. This implementation includes:

- Structured threat modeling using STRIDE and DREAD methodologies
- Service-specific risk assessments
- Integration with AWS Trusted Advisor
- Vulnerability scoring and prioritization
- Automated reporting and dashboards

These components work together to provide continuous risk assessment and visibility into your AWS environment's security posture. 