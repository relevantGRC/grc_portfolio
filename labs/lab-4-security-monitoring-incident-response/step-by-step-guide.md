# Lab 4: Security Monitoring and Incident Response - Step-by-Step Guide

This guide will walk you through implementing a comprehensive security monitoring and incident response solution in AWS. Follow each module sequentially to build out your solution.

## Module 1: Centralized Logging and Monitoring

### Step 1: Configure AWS CloudTrail

1. Sign in to your AWS Management Console and navigate to the CloudTrail service.

2. Click **Create trail** and configure the following settings:
   - Trail name: `SecurityMonitoringTrail`
   - Storage location: Create a new S3 bucket with a unique name, e.g., `security-logs-[account-id]`
   - Log file validation: **Enabled**
   - KMS encryption: **Enabled** (create a new KMS key for log encryption)
   - Log file prefix: `cloudtrail/`
   - CloudWatch Logs: **Enabled**
   - Log group name: `/aws/cloudtrail/SecurityMonitoringTrail`
   - IAM Role: Create a new role with the name `CloudTrailToCloudWatchRole`

3. For event selection, choose:
   - Management events: **All**
   - Data events: **None** (for production, consider enabling S3 and Lambda data events)
   - Insights events: **Enabled**

4. Click **Create trail**.

### Step 2: Set Up CloudWatch Log Groups with Metric Filters

1. Navigate to the CloudWatch service.

2. Go to **Logs** > **Log groups** and verify the `/aws/cloudtrail/SecurityMonitoringTrail` log group exists.

3. Add metric filters for key security events. Click **Actions** > **Create metric filter**:

   a. Root user login filter:
      - Filter pattern: `{ $.userIdentity.type = "Root" && $.eventType != "AwsServiceEvent" }`
      - Filter name: `RootUserLoginAttempt`
      - Metric namespace: `SecurityMetrics`
      - Metric name: `RootUserLoginCount`
      - Metric value: `1`

   b. IAM policy changes filter:
      - Filter pattern: `{ ($.eventName = CreatePolicy) || ($.eventName = DeletePolicy) || ($.eventName = CreatePolicyVersion) || ($.eventName = DeletePolicyVersion) || ($.eventName = AttachRolePolicy) || ($.eventName = DetachRolePolicy) || ($.eventName = AttachUserPolicy) || ($.eventName = DetachUserPolicy) || ($.eventName = AttachGroupPolicy) || ($.eventName = DetachGroupPolicy) }`
      - Filter name: `IAMPolicyChanges`
      - Metric namespace: `SecurityMetrics`
      - Metric name: `IAMPolicyChangeCount`
      - Metric value: `1`

   c. Security group changes filter:
      - Filter pattern: `{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }`
      - Filter name: `SecurityGroupChanges`
      - Metric namespace: `SecurityMetrics`
      - Metric name: `SecurityGroupChangeCount`
      - Metric value: `1`

   d. Failed console login attempts:
      - Filter pattern: `{ ($.eventName = ConsoleLogin) && ($.errorMessage = "Failed authentication") }`
      - Filter name: `FailedConsoleLogins`
      - Metric namespace: `SecurityMetrics`
      - Metric name: `FailedConsoleLoginCount`
      - Metric value: `1`

### Step 3: Create CloudWatch Alarms for Security Events

1. In CloudWatch, go to **Alarms** > **All alarms** > **Create alarm**.

2. Click **Select metric** and navigate to the `SecurityMetrics` namespace.

3. Create the following alarms:

   a. Root User Login Alarm:
      - Select the `RootUserLoginCount` metric
      - Statistic: Sum
      - Period: 5 minutes
      - Threshold type: Static
      - Condition: Greater than or equal to 1
      - Alarm name: `RootUserLoginAlarm`

   b. IAM Policy Changes Alarm:
      - Select the `IAMPolicyChangeCount` metric
      - Statistic: Sum
      - Period: 5 minutes
      - Threshold type: Static
      - Condition: Greater than or equal to 3
      - Alarm name: `IAMPolicyChangesAlarm`

   c. Security Group Changes Alarm:
      - Select the `SecurityGroupChangeCount` metric
      - Statistic: Sum
      - Period: 5 minutes
      - Threshold type: Static
      - Condition: Greater than or equal to 3
      - Alarm name: `SecurityGroupChangesAlarm`

   d. Failed Console Logins Alarm:
      - Select the `FailedConsoleLoginCount` metric
      - Statistic: Sum
      - Period: 5 minutes
      - Threshold type: Static
      - Condition: Greater than or equal to 5
      - Alarm name: `FailedConsoleLoginsAlarm`

4. For each alarm, create an SNS notification (we'll set up the SNS topic in Module 2).

### Step 4: Implement CloudWatch Dashboard for Security Visibility

1. In CloudWatch, go to **Dashboards** > **Create dashboard**.

2. Name the dashboard `SecurityMonitoringDashboard`.

3. Add widgets for each security metric:
   - Add **Line** widgets for each security metric
   - Add **Alarm Status** widgets to show the status of your security alarms
   - Add **Text** widgets to provide context and descriptions

4. Arrange the widgets for optimal visibility and save the dashboard.

## Module 2: Threat Detection and Alerting

### Step 1: Enable and Configure Amazon GuardDuty

1. Navigate to the GuardDuty service.

2. Click **Get Started** or **Enable GuardDuty**.

3. Click **Enable GuardDuty** to enable the service with default settings.

4. Once enabled, explore the **Settings** tab and enable the following protection plans:
   - S3 Protection
   - EKS Protection (if using Kubernetes)
   - Malware Protection

5. Configure findings export to an S3 bucket:
   - Click on **Settings** > **Findings export options**
   - Click **Configure now**
   - Create a new S3 bucket or use your existing security logs bucket
   - Enable KMS encryption

### Step 2: Set Up AWS Security Hub

1. Navigate to the Security Hub service.

2. Click **Go to Security Hub** or **Enable Security Hub**.

3. Select the following compliance standards:
   - AWS Foundational Security Best Practices
   - CIS AWS Foundations Benchmark
   - PCI DSS

4. Click **Enable Security Hub**.

5. After enabling, configure integrations:
   - Navigate to **Integrations**
   - Enable integration with GuardDuty
   - Enable integration with AWS Config
   - Enable any other relevant integrations

### Step 3: Configure AWS Config Rules for Security Compliance

1. Navigate to the AWS Config service.

2. If not already set up, click **Get started** and configure:
   - Recording method: Record all resources supported in this region
   - Storage location: Use your security logs bucket
   - Create a new IAM role for AWS Config

3. Once configured, navigate to **Rules** > **Add rule**.

4. Add the following managed rules:
   - `cloudtrail-enabled`
   - `cloud-trail-encryption-enabled`
   - `cloudtrail-s3-dataevents-enabled`
   - `guardduty-enabled-centralized`
   - `securityhub-enabled`
   - `s3-bucket-public-read-prohibited`
   - `s3-bucket-public-write-prohibited`
   - `s3-bucket-server-side-encryption-enabled`
   - `restricted-ssh`
   - `restricted-common-ports`
   - `vpc-flow-logs-enabled`

### Step 4: Implement SNS Topics and Subscriptions

1. Navigate to the Amazon SNS service.

2. Click **Topics** > **Create topic**.

3. Create a Standard topic named `SecurityAlerts`.

4. Configure encryption with your KMS key for log encryption.

5. Create a subscription for this topic:
   - Click **Create subscription**
   - Protocol: Email
   - Endpoint: Your email address
   - Click **Create subscription**

6. Confirm the subscription via the email you receive.

7. Update the CloudWatch alarms you created earlier to use this SNS topic.

### Step 5: Create EventBridge Rules for Security Events

1. Navigate to the Amazon EventBridge service.

2. Click **Rules** > **Create rule**.

3. Create the following rules:

   a. GuardDuty High Severity Finding Rule:
      - Name: `GuardDutyHighSeverityFindings`
      - Description: Detects high severity GuardDuty findings
      - Event pattern:
        ```json
        {
          "source": ["aws.guardduty"],
          "detail-type": ["GuardDuty Finding"],
          "detail": {
            "severity": [7, 8, 9]
          }
        }
        ```
      - Target: SNS topic (`SecurityAlerts`)

   b. Security Hub Critical Finding Rule:
      - Name: `SecurityHubCriticalFindings`
      - Description: Detects critical Security Hub findings
      - Event pattern:
        ```json
        {
          "source": ["aws.securityhub"],
          "detail-type": ["Security Hub Findings - Imported"],
          "detail": {
            "findings": {
              "Severity": {
                "Label": ["CRITICAL", "HIGH"]
              },
              "Workflow": {
                "Status": ["NEW"]
              }
            }
          }
        }
        ```
      - Target: SNS topic (`SecurityAlerts`)

   c. AWS Config Non-Compliant Resource Rule:
      - Name: `ConfigNonCompliantResources`
      - Description: Detects non-compliant resources in AWS Config
      - Event pattern:
        ```json
        {
          "source": ["aws.config"],
          "detail-type": ["Config Rules Compliance Change"],
          "detail": {
            "messageType": ["ComplianceChangeNotification"],
            "newEvaluationResult": {
              "complianceType": ["NON_COMPLIANT"]
            }
          }
        }
        ```
      - Target: SNS topic (`SecurityAlerts`)

## Module 3: Incident Response Automation

### Step 1: Create an S3 Bucket for Incident Response Scripts and Results

1. Navigate to the S3 service.

2. Click **Create bucket**.

3. Name the bucket `incident-response-[account-id]`.

4. Enable versioning and encryption.

5. Block all public access.

6. Create the following folders:
   - `scripts/` - Will store automation scripts
   - `playbooks/` - Will store incident response playbooks
   - `evidence/` - Will store incident evidence and investigation results

### Step 2: Create Lambda Functions for Automated Response

1. Navigate to the Lambda service.

2. Create the following Lambda functions:

   a. Compromised IAM Credentials Responder:
      - Name: `CompromisedIAMCredentialsResponder`
      - Runtime: Python 3.9
      - Create a new execution role with the following permissions:
        - IAM:DeleteAccessKey
        - IAM:UpdateAccessKey
        - S3:PutObject
      - Function code (provided in the `code/scripts/lambda-functions/compromised-iam-credentials-responder.py` file)
      - Environment variables:
        - `EVIDENCE_BUCKET`: Your incident response bucket name
        - `EVIDENCE_PREFIX`: `evidence/iam-credential-compromise/`

   b. Unauthorized API Call Responder:
      - Name: `UnauthorizedAPICallResponder`
      - Runtime: Python 3.9
      - Create a new execution role with the following permissions:
        - IAM:AttachUserPolicy
        - IAM:PutUserPolicy
        - S3:PutObject
      - Function code (provided in the `code/scripts/lambda-functions/unauthorized-api-call-responder.py` file)
      - Environment variables:
        - `EVIDENCE_BUCKET`: Your incident response bucket name
        - `EVIDENCE_PREFIX`: `evidence/unauthorized-api-calls/`

   c. Public S3 Bucket Remediation:
      - Name: `PublicS3BucketRemediator`
      - Runtime: Python 3.9
      - Create a new execution role with the following permissions:
        - S3:GetBucketPolicyStatus
        - S3:PutBucketPublicAccessBlock
        - S3:PutBucketPolicy
        - S3:PutObject
      - Function code (provided in the `code/scripts/lambda-functions/public-s3-bucket-remediator.py` file)
      - Environment variables:
        - `EVIDENCE_BUCKET`: Your incident response bucket name
        - `EVIDENCE_PREFIX`: `evidence/public-s3-buckets/`

### Step 3: Create Systems Manager Automation Documents

1. Navigate to the AWS Systems Manager service.

2. Click **Documents** > **Create document**.

3. Create the following automation documents:

   a. Security Group Remediation Document:
      - Name: `SecurityGroupRemediationRunbook`
      - Document type: Automation
      - Content: Use the JSON provided in `code/scripts/ssm-documents/security-group-remediation.json`

   b. Host Isolation Document:
      - Name: `HostIsolationRunbook`
      - Document type: Automation
      - Content: Use the JSON provided in `code/scripts/ssm-documents/host-isolation.json`

   c. Instance Forensics Document:
      - Name: `InstanceForensicsRunbook`
      - Document type: Automation
      - Content: Use the JSON provided in `code/scripts/ssm-documents/instance-forensics.json`

### Step 4: Configure EventBridge Rules to Trigger Response Actions

1. Return to the Amazon EventBridge service.

2. Create the following rules to trigger your automated responses:

   a. IAM Credential Compromise Rule:
      - Name: `IAMCredentialCompromiseResponse`
      - Description: Triggers automated response for compromised IAM credentials
      - Event pattern:
        ```json
        {
          "source": ["aws.guardduty"],
          "detail-type": ["GuardDuty Finding"],
          "detail": {
            "type": ["UnauthorizedAccess:IAMUser/MaliciousIPCaller", "UnauthorizedAccess:IAMUser/MaliciousIPCaller.Custom", "Discovery:IAMUser/MaliciousIPCaller", "Persistence:IAMUser/MaliciousIPCaller"],
            "severity": [7, 8, 9]
          }
        }
        ```
      - Target: Lambda function (`CompromisedIAMCredentialsResponder`)

   b. Unauthorized API Call Rule:
      - Name: `UnauthorizedAPICallResponse`
      - Description: Triggers automated response for unauthorized API calls
      - Event pattern:
        ```json
        {
          "source": ["aws.guardduty"],
          "detail-type": ["GuardDuty Finding"],
          "detail": {
            "type": ["UnauthorizedAccess:IAMUser/ConsoleLoginSuccess.B", "UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration"],
            "severity": [7, 8, 9]
          }
        }
        ```
      - Target: Lambda function (`UnauthorizedAPICallResponder`)

   c. Public S3 Bucket Rule:
      - Name: `PublicS3BucketResponse`
      - Description: Triggers automated response for public S3 buckets
      - Event pattern:
        ```json
        {
          "source": ["aws.config"],
          "detail-type": ["Config Rules Compliance Change"],
          "detail": {
            "configRuleName": ["s3-bucket-public-read-prohibited", "s3-bucket-public-write-prohibited"],
            "newEvaluationResult": {
              "complianceType": ["NON_COMPLIANT"]
            }
          }
        }
        ```
      - Target: Lambda function (`PublicS3BucketRemediator`)

### Step 5: Implement Notification Escalation Procedures

1. Create additional SNS topics for different severity levels:
   - `SecurityAlerts-Critical`
   - `SecurityAlerts-High`
   - `SecurityAlerts-Medium`
   - `SecurityAlerts-Low`

2. Configure appropriate subscriptions for each topic based on your organization's escalation procedures.

3. Create a Lambda function to handle notification routing based on severity:
   - Name: `SecurityAlertRouter`
   - Runtime: Python 3.9
   - Code: Use the template provided in `code/scripts/lambda-functions/security-alert-router.py`
   - Configure this Lambda to receive events from your security services and route notifications to the appropriate SNS topic.

## Module 4: Incident Response Playbooks

In this module, you will create several incident response playbooks for common security scenarios. We'll provide templates in the `code/scripts/playbooks/` directory.

### Step 1: Create Investigation Procedures

Create the following investigation procedure documents:

1. Navigate to your incident response S3 bucket.

2. Upload the following playbooks to the `playbooks/` directory:
   - `general-investigation-procedure.md`
   - `compromised-credentials-playbook.md`
   - `data-exfiltration-playbook.md`
   - `malware-response-playbook.md`
   - `ddos-response-playbook.md`
   - `privilege-escalation-playbook.md`

Each playbook contains:
- Initial response actions
- Investigation procedures
- Containment strategies
- Eradication steps
- Recovery procedures
- Post-incident activities

### Step 2: Automation Integration

For each playbook, identify automation opportunities:

1. Review each playbook to identify steps that can be automated.

2. Create additional Lambda functions or Systems Manager Automation documents as needed.

3. Link these automation resources to the appropriate playbooks.

4. Update the EventBridge rules to trigger these automations when relevant events occur.

## Module 5: Security Incident Simulations

### Step 1: Prepare for Security Simulations

1. Create a simulation planning document that includes:
   - Objectives of the simulation
   - Scope and boundaries
   - Roles and responsibilities
   - Communication plan
   - Testing timeline

2. Notify all relevant stakeholders before conducting simulations.

### Step 2: Simulate a Compromised IAM Credential

1. Use the AWS CLI to simulate a GuardDuty finding:
   ```bash
   aws guardduty create-sample-findings --detector-id YOUR_DETECTOR_ID --finding-types UnauthorizedAccess:IAMUser/MaliciousIPCaller
   ```

2. Observe the automated response:
   - Check your email for alerts
   - Verify that the Lambda function was triggered
   - Review the evidence collected in your incident response bucket

3. Document the response and identify areas for improvement.

### Step 3: Simulate a Public S3 Bucket

1. Create a test S3 bucket.

2. Make the bucket publicly accessible (for testing purposes only).

3. Wait for AWS Config to detect the non-compliant resource.

4. Observe the automated response:
   - Check your email for alerts
   - Verify that the Lambda function was triggered
   - Confirm that the bucket's public access was blocked
   - Review the evidence collected in your incident response bucket

5. Document the response and identify areas for improvement.

### Step 4: Conduct a Tabletop Exercise

1. Gather your security team for a tabletop exercise.

2. Present a security incident scenario based on one of your playbooks.

3. Walk through the playbook steps, discussing actions, decisions, and responsibilities.

4. Document the exercise outcomes and identify areas for improvement.

## Validation and Next Steps

### Step 1: Validate Your Implementation

1. Complete the validation checklist provided in `validation-checklist.md`.

2. Verify that all components are working as expected:
   - Logging is properly configured
   - Security services are generating appropriate findings
   - Alerts are being sent to the correct destinations
   - Automated responses are functioning correctly
   - Playbooks are comprehensive and accessible

### Step 2: Next Steps

1. Consider enhancing your solution with:
   - Integration with existing SIEM systems
   - Advanced threat hunting capabilities
   - Machine learning-based anomaly detection
   - Automated threat intelligence feeds

2. Document your implementation and share lessons learned with your team.

3. Establish a regular schedule for reviewing and updating your security monitoring and incident response capabilities.

## Cleanup (When No Longer Needed)

To avoid ongoing charges, remember to clean up resources when you no longer need them:

1. Disable GuardDuty, Security Hub, and AWS Config.

2. Delete CloudWatch Alarms and Dashboards.

3. Delete Lambda functions, EventBridge rules, and SNS topics.

4. Empty and delete S3 buckets.

5. Delete IAM roles created for this lab.

## Conclusion

Congratulations! You have successfully implemented a comprehensive security monitoring and incident response solution in AWS. This foundation will help you detect, respond to, and recover from security incidents more effectively, improving your overall security posture. 