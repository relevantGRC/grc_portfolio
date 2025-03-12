# Incident Response Playbook: Compromised IAM Credentials

## Overview
This playbook outlines the procedures for responding to a suspected or confirmed compromise of AWS IAM credentials. IAM credential compromise can lead to unauthorized access to AWS resources, data exfiltration, resource exploitation, or further lateral movement within the AWS environment.

## Incident Classification
- **Severity**: High
- **Categories**:
  - Unauthorized Access
  - Identity and Access Management
  - Data Loss/Exfiltration Risk
- **NIST CSF Functions**: Detect, Respond, Recover

## Detection Sources
- **AWS GuardDuty Findings**:
  - UnauthorizedAccess:IAMUser/ConsoleLoginSuccess.B
  - UnauthorizedAccess:IAMUser/MaliciousIPCaller
  - UnauthorizedAccess:IAMUser/TorIPCaller
  - CredentialAccess:IAMUser/AnomalousBehavior
- **CloudTrail Events**:
  - Unusual API activity from unfamiliar IP addresses
  - API calls from geographically distant locations within short timeframes
  - Unusual frequency of API calls
  - High-risk API calls (e.g., CreateAccessKey, UpdateLoginProfile)
- **CloudWatch Alarms**:
  - Triggered when IAM policy changes are detected
  - Multiple failed console login attempts
  - Geographic access patterns outside normal business regions
- **Security Hub Findings**:
  - Aggregated security findings related to IAM users or roles

## Initial Response Actions

| Action | Description | Owner | SLA |
|--------|-------------|-------|-----|
| Validate Finding | Confirm the authenticity of the security alert and determine if this is a true positive | Security Engineer | 30 minutes |
| Initial Containment | If high confidence that credentials are compromised, immediately disable the affected credentials | Security Engineer | 1 hour |
| Create Incident Ticket | Document the incident with all available information in the incident management system | Incident Manager | 1 hour |
| Notify Stakeholders | Inform relevant teams based on escalation procedures | Incident Manager | 2 hours |
| Preserve Evidence | Ensure all relevant logs and data are preserved for investigation | Forensics Team | 4 hours |

## Investigation Process

| Action | Description | Owner | SLA |
|--------|-------------|-------|-----|
| Activity Timeline | Create a timeline of all activities performed with the suspected credentials from CloudTrail logs | Security Analyst | 4 hours |
| Resource Assessment | Identify all AWS resources accessed or modified by the compromised credentials | Security Analyst | 6 hours |
| Attack Vector Analysis | Determine how the credentials were compromised (e.g., phishing, malware, insider threat) | Security Analyst | 8 hours |
| Impact Assessment | Evaluate potential data exposure, resource compromise, or financial impact | Security Analyst | 12 hours |
| Threat Actor Profiling | If possible, gather intelligence about the threat actor based on TTP analysis | Threat Intelligence | 24 hours |

## Containment, Eradication, and Recovery

### Containment
1. Disable or delete the compromised IAM user credentials:
   ```bash
   aws iam update-access-key --access-key-id ACCESS_KEY_ID --status Inactive --user-name USER_NAME
   ```
2. Revoke all active sessions for the affected user or role:
   ```bash
   aws iam create-policy-version --policy-arn USER_POLICY_ARN --policy-document file://deny-all-policy.json --set-as-default
   ```
3. Implement IP restrictions for the affected account if applicable

### Eradication
1. Delete compromised access keys:
   ```bash
   aws iam delete-access-key --access-key-id ACCESS_KEY_ID --user-name USER_NAME
   ```
2. Rotate all credentials that may have been exposed
3. Remove any unauthorized resources created by the attacker:
   ```bash
   # Identify resources created during the compromise timeframe
   aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances --start-time COMPROMISE_START_TIME --end-time COMPROMISE_END_TIME
   ```
4. Remove any backdoor IAM users, roles, or policies created by the attacker

### Recovery
1. Create new IAM credentials with appropriate permissions
2. Restore normal service operations with clean credentials
3. Verify that all unauthorized access has been removed
4. Implement additional security controls if needed:
   - Enforce MFA for IAM users
   - Implement stricter IAM permission boundaries
   - Enable GuardDuty for enhanced monitoring

## Post-Incident Activities

| Action | Description | Owner | SLA |
|--------|-------------|-------|-----|
| Incident Documentation | Complete all documentation related to the incident | Incident Manager | 24 hours |
| Lessons Learned | Conduct a post-incident review to identify gaps and improvement areas | Security Team | 1 week |
| Update Detection | Enhance detection capabilities based on the incident patterns | Security Engineering | 2 weeks |
| Preventative Measures | Implement additional security controls to prevent similar incidents | Security Architecture | 2 weeks |
| Training | Update security awareness training with lessons from this incident | Security Training | 1 month |

## Automation Opportunities

### Detection Automation
- CloudWatch Events rule to automatically trigger alerts on suspicious IAM activity
- GuardDuty custom insights for IAM credential usage patterns

### Containment Automation
- Lambda function to automatically disable suspicious access keys:
  ```python
  import boto3
  
  def lambda_handler(event, context):
      iam = boto3.client('iam')
      username = event['detail']['userIdentity']['userName']
      access_key_id = event['detail']['requestParameters']['accessKeyId']
      
      response = iam.update_access_key(
          UserName=username,
          AccessKeyId=access_key_id,
          Status='Inactive'
      )
      
      return response
  ```

### Investigation Automation
- EventBridge integration to automate evidence collection
- Automated timeline generation script using CloudTrail data

### Recovery Automation
- Automated policy review script to identify overly permissive policies

## Metrics and KPIs
- Mean Time to Detect (MTTD): Target < 2 hours
- Mean Time to Respond (MTTR): Target < 4 hours
- Mean Time to Contain (MTTC): Target < 6 hours
- Mean Time to Recovery (MTTR): Target < 24 hours
- Percentage of automated containment actions: Target > 80%

## References
- [AWS Security Incident Response Guide](https://docs.aws.amazon.com/whitepapers/latest/aws-security-incident-response-guide/welcome.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS GuardDuty Finding Types](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_finding-types-active.html)

## Appendices

### Appendix A: Sample Deny-All Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
```

### Appendix B: Evidence Collection Checklist
- [ ] CloudTrail logs for the affected time period
- [ ] CloudWatch Logs for relevant services
- [ ] VPC Flow Logs for network traffic analysis
- [ ] IAM credential reports
- [ ] Access Analyzer findings
- [ ] GuardDuty findings

### Appendix C: Contact Information
- Incident Response Team: ir-team@example.com
- AWS Support: https://console.aws.amazon.com/support/home
- Security Operations Center: soc@example.com, +1-555-123-4567 