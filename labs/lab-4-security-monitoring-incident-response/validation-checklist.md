# Lab 4: Security Monitoring and Incident Response - Validation Checklist

Use this checklist to verify that you've successfully completed all the required tasks for Lab 4. Check off each item as you confirm your implementation meets the requirements.

## Module 1: Centralized Logging and Monitoring

### CloudTrail Configuration
- [ ] CloudTrail trail created with the name `SecurityMonitoringTrail`
- [ ] Trail configured to log to an S3 bucket with appropriate naming
- [ ] Log file validation enabled
- [ ] KMS encryption enabled
- [ ] Trail configured to send logs to CloudWatch Logs
- [ ] Management events enabled with read and write events
- [ ] Insights events enabled

### CloudWatch Log Groups and Metric Filters
- [ ] CloudWatch Log Group for CloudTrail exists (`/aws/cloudtrail/SecurityMonitoringTrail`)
- [ ] Root user login metric filter created
- [ ] IAM policy changes metric filter created
- [ ] Security group changes metric filter created
- [ ] Failed console login attempts metric filter created
- [ ] All metric filters using the correct namespace (`SecurityMetrics`)

### CloudWatch Alarms
- [ ] Root user login alarm created
- [ ] IAM policy changes alarm created
- [ ] Security group changes alarm created
- [ ] Failed console logins alarm created
- [ ] All alarms configured with appropriate thresholds
- [ ] All alarms linked to an SNS topic for notifications

### CloudWatch Dashboard
- [ ] Security monitoring dashboard created
- [ ] Dashboard includes widgets for all security metrics
- [ ] Dashboard includes alarm status widgets
- [ ] Dashboard includes descriptive text widgets

## Module 2: Threat Detection and Alerting

### GuardDuty Configuration
- [ ] GuardDuty enabled in your AWS account
- [ ] S3 Protection enabled
- [ ] Malware Protection enabled (if applicable)
- [ ] Findings export configured to an S3 bucket
- [ ] KMS encryption enabled for findings export

### Security Hub Configuration
- [ ] Security Hub enabled in your AWS account
- [ ] AWS Foundational Security Best Practices standard enabled
- [ ] CIS AWS Foundations Benchmark standard enabled
- [ ] PCI DSS standard enabled (if applicable)
- [ ] GuardDuty integration enabled
- [ ] AWS Config integration enabled

### AWS Config Rules
- [ ] AWS Config enabled with all resource types recorded
- [ ] `cloudtrail-enabled` rule added
- [ ] `cloud-trail-encryption-enabled` rule added
- [ ] `cloudtrail-s3-dataevents-enabled` rule added
- [ ] `guardduty-enabled-centralized` rule added
- [ ] `securityhub-enabled` rule added
- [ ] `s3-bucket-public-read-prohibited` rule added
- [ ] `s3-bucket-public-write-prohibited` rule added
- [ ] `s3-bucket-server-side-encryption-enabled` rule added
- [ ] `restricted-ssh` rule added
- [ ] `restricted-common-ports` rule added
- [ ] `vpc-flow-logs-enabled` rule added

### SNS Topics and Subscriptions
- [ ] `SecurityAlerts` SNS topic created
- [ ] Topic configured with appropriate encryption
- [ ] Subscription created and confirmed for your email address
- [ ] CloudWatch alarms updated to use this SNS topic

### EventBridge Rules
- [ ] `GuardDutyHighSeverityFindings` rule created
- [ ] `SecurityHubCriticalFindings` rule created
- [ ] `ConfigNonCompliantResources` rule created
- [ ] All rules configured with the correct event patterns
- [ ] All rules targeted to the `SecurityAlerts` SNS topic

## Module 3: Incident Response Automation

### S3 Bucket for Incident Response
- [ ] Incident response bucket created with appropriate naming (`incident-response-[account-id]`)
- [ ] Versioning enabled
- [ ] Encryption enabled
- [ ] Public access blocked
- [ ] Appropriate folders created (scripts, playbooks, evidence)

### Lambda Functions for Automated Response
- [ ] `CompromisedIAMCredentialsResponder` Lambda function created
- [ ] `UnauthorizedAPICallResponder` Lambda function created
- [ ] `PublicS3BucketRemediator` Lambda function created
- [ ] All Lambda functions configured with appropriate IAM roles and permissions
- [ ] All Lambda functions include appropriate environment variables

### Systems Manager Automation Documents
- [ ] `SecurityGroupRemediationRunbook` document created
- [ ] `HostIsolationRunbook` document created
- [ ] `InstanceForensicsRunbook` document created
- [ ] All documents containing the correct automation steps

### EventBridge Rules for Response Automation
- [ ] `IAMCredentialCompromiseResponse` rule created
- [ ] `UnauthorizedAPICallResponse` rule created
- [ ] `PublicS3BucketResponse` rule created
- [ ] All rules configured with appropriate event patterns
- [ ] All rules targeted to the correct Lambda functions

### Notification Escalation Procedures
- [ ] Additional severity-based SNS topics created
- [ ] Appropriate subscriptions configured for each topic
- [ ] `SecurityAlertRouter` Lambda function created and configured

## Module 4: Incident Response Playbooks

### Investigation Procedures
- [ ] General investigation procedure document created
- [ ] Compromised credentials playbook created
- [ ] Data exfiltration playbook created
- [ ] Malware response playbook created
- [ ] DDoS response playbook created
- [ ] Privilege escalation playbook created
- [ ] All playbooks uploaded to the incident response S3 bucket

### Automation Integration
- [ ] Playbooks reviewed for automation opportunities
- [ ] Additional automation components created as needed
- [ ] Automation components linked to appropriate playbooks
- [ ] EventBridge rules updated to trigger automations

## Module 5: Security Incident Simulations

### Simulation Preparation
- [ ] Simulation planning document created
- [ ] Relevant stakeholders notified

### Compromised IAM Credential Simulation
- [ ] GuardDuty finding simulation executed
- [ ] Alert notifications received
- [ ] Lambda function triggered
- [ ] Evidence collected in incident response bucket
- [ ] Response documented and improvements identified

### Public S3 Bucket Simulation
- [ ] Test S3 bucket created and made public
- [ ] AWS Config detection observed
- [ ] Alert notifications received
- [ ] Lambda function triggered
- [ ] Public access blocked automatically
- [ ] Evidence collected in incident response bucket
- [ ] Response documented and improvements identified

### Tabletop Exercise
- [ ] Security team gathered for exercise
- [ ] Incident scenario presented
- [ ] Playbook steps followed
- [ ] Exercise outcomes documented
- [ ] Improvements identified

## Overall Validation

### Monitoring and Detection
- [ ] All AWS API activity is logged
- [ ] Security events generate appropriate alerts
- [ ] Threat detection services are properly configured
- [ ] Security findings are visible in Security Hub

### Alerting and Notification
- [ ] Security alerts are sent to the correct destinations
- [ ] Notifications include relevant incident details
- [ ] Escalation procedures work as expected

### Automated Response
- [ ] Automated responses trigger based on security events
- [ ] Response actions are appropriate and effective
- [ ] Evidence is collected for investigation

### Documentation and Procedures
- [ ] All playbooks are comprehensive and accessible
- [ ] Investigation procedures are clear and actionable
- [ ] Automation components are well-documented

## Final Checklist

- [ ] Take screenshots of:
  - [ ] CloudTrail configuration
  - [ ] CloudWatch Dashboard
  - [ ] GuardDuty settings
  - [ ] Security Hub compliance scores
  - [ ] AWS Config rule compliance
  - [ ] Lambda function configurations
  - [ ] EventBridge rules
  - [ ] Incident response playbooks
  - [ ] Simulation results

- [ ] Document any deviations from the lab instructions and the reasons for those deviations

Congratulations on completing Lab 4: Security Monitoring and Incident Response! Your implementation should now provide you with comprehensive security monitoring capabilities and effective incident response procedures. 