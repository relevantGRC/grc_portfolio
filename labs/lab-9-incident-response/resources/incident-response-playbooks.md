# Incident Response Playbooks

This document provides detailed playbooks for responding to common security incidents in AWS environments.

## 1. Compromised IAM Credentials

### Detection
- GuardDuty finding: `UnauthorizedAccess:IAMUser/MaliciousIPCaller`
- CloudTrail events from unusual IP addresses
- Multiple failed API calls
- Unusual resource creation or deletion

### Response Steps
1. **Immediate Actions**
   - Disable compromised IAM user/role
   - Revoke active sessions using `aws iam revoke-sessions`
   - Delete unauthorized access keys
   - Enable MFA if not already enabled

2. **Investigation**
   - Review CloudTrail for user activity
   - Identify resources accessed/modified
   - Document unauthorized actions
   - Determine entry point and timeline

3. **Remediation**
   - Rotate all access keys
   - Update IAM policies
   - Remove unauthorized resources
   - Verify remaining access keys
   - Enable additional monitoring

4. **Recovery**
   - Create new IAM user/role if needed
   - Restore from known good backups
   - Verify service functionality
   - Update documentation

## 2. Cryptomining Detection

### Detection
- GuardDuty finding: `CryptoCurrency:EC2/BitcoinTool.B`
- High CPU utilization
- Unusual network traffic
- Unknown processes
- Unexpected costs

### Response Steps
1. **Immediate Actions**
   - Isolate affected instances
   - Block suspicious IP addresses
   - Capture memory dump
   - Take EBS snapshots

2. **Investigation**
   - Analyze memory dumps
   - Review process lists
   - Check startup scripts
   - Examine network connections

3. **Remediation**
   - Terminate compromised instances
   - Update security groups
   - Patch vulnerabilities
   - Strengthen access controls

4. **Recovery**
   - Launch clean instances
   - Restore verified backups
   - Update monitoring
   - Document incident

## 3. Data Exfiltration

### Detection
- GuardDuty finding: `UnauthorizedAccess:EC2/TorIPCaller`
- Large data transfers
- Unusual API calls
- Access from unknown IPs
- S3 bucket policy changes

### Response Steps
1. **Immediate Actions**
   - Block suspicious IPs
   - Revoke IAM credentials
   - Enable bucket logging
   - Capture network traffic

2. **Investigation**
   - Review S3 access logs
   - Analyze VPC Flow Logs
   - Check CloudTrail events
   - Document data access

3. **Remediation**
   - Update bucket policies
   - Strengthen IAM roles
   - Enable encryption
   - Implement better monitoring

4. **Recovery**
   - Verify data integrity
   - Restore from backups
   - Update access controls
   - Enhance DLP controls

## 4. Ransomware Attack

### Detection
- Multiple file modifications
- Unusual encryption processes
- Ransom notes
- System performance issues
- Blocked access to resources

### Response Steps
1. **Immediate Actions**
   - Isolate affected systems
   - Block malicious IPs
   - Disable compromised accounts
   - Create forensic copies

2. **Investigation**
   - Analyze malware samples
   - Identify infection vector
   - Document encrypted files
   - Determine blast radius

3. **Remediation**
   - Remove malware
   - Patch vulnerabilities
   - Update security controls
   - Strengthen backups

4. **Recovery**
   - Restore from clean backups
   - Verify system integrity
   - Update monitoring
   - Document lessons learned

## 5. DDoS Attack

### Detection
- High network traffic
- Service degradation
- AWS Shield alerts
- WAF triggers
- Unusual patterns

### Response Steps
1. **Immediate Actions**
   - Enable AWS Shield Advanced
   - Scale resources
   - Update WAF rules
   - Contact AWS Support

2. **Investigation**
   - Analyze traffic patterns
   - Identify attack vectors
   - Document impact
   - Review logs

3. **Remediation**
   - Update security groups
   - Strengthen WAF rules
   - Enable rate limiting
   - Implement protection

4. **Recovery**
   - Scale down resources
   - Verify service health
   - Update documentation
   - Enhance monitoring

## Best Practices

### Documentation
- Maintain detailed logs
- Document all actions
- Keep timeline of events
- Record lessons learned

### Communication
- Define escalation paths
- Maintain contact lists
- Regular status updates
- Clear incident reports

### Tools and Resources
- AWS Security Hub
- GuardDuty
- CloudWatch
- AWS Config
- Systems Manager
- CloudTrail

### Post-Incident
- Review response effectiveness
- Update playbooks
- Improve controls
- Train team members
- Share lessons learned

## Incident Severity Levels

### Level 1 - Critical
- Data breach
- Ransomware
- System compromise
- Service outage
- Response: Immediate

### Level 2 - High
- Suspected compromise
- Performance impact
- Limited breach
- Response: < 1 hour

### Level 3 - Medium
- Policy violations
- Suspicious activity
- Minor incidents
- Response: < 4 hours

### Level 4 - Low
- Minor violations
- System alerts
- Routine issues
- Response: < 24 hours

## Incident Response Team

### Roles and Responsibilities
- Incident Commander
- Technical Lead
- Security Analyst
- System Administrator
- Communications Lead
- Legal Representative

### Contact Information
- Primary contacts
- Backup contacts
- External resources
- AWS Support
- Legal team

## Regulatory Requirements

### Compliance
- Document all actions
- Maintain evidence
- Follow procedures
- Meet deadlines
- Report as required

### Privacy
- Protect PII/PHI
- Secure evidence
- Control access
- Document handling

## Templates

### Incident Report
```
Incident ID: 
Date/Time: 
Severity: 
Type: 
Description: 
Impact: 
Actions Taken: 
Resolution: 
Lessons Learned: 
```

### Communication Template
```
Subject: Security Incident Update
Status: [Active/Resolved]
Severity: 
Impact: 
Actions: 
Next Steps: 
Contact: 
```

### Chain of Custody
```
Evidence ID: 
Description: 
Collection Date: 
Collector: 
Location: 
Hash: 
Handling: 
``` 