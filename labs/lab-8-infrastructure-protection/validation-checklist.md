# Lab 8: Infrastructure and Network Protection - Validation Checklist

Use this checklist to verify that you have successfully implemented all the required components of the Infrastructure and Network Protection lab. Each section corresponds to a module in the step-by-step guide.

## Module 1: Secure VPC Design

### VPC Configuration
- [ ] VPC created with appropriate CIDR block (10.0.0.0/16)
- [ ] DNS hostnames and DNS support enabled
- [ ] All required tags are applied
- [ ] No default network ACLs or security groups are in use

### Subnet Layout
- [ ] Public subnets created in two AZs
  - [ ] Correct CIDR blocks assigned
  - [ ] Auto-assign public IP enabled
  - [ ] Properly tagged
- [ ] Private web tier subnets created in two AZs
  - [ ] Correct CIDR blocks assigned
  - [ ] Auto-assign public IP disabled
  - [ ] Properly tagged
- [ ] Private app tier subnets created in two AZs
  - [ ] Correct CIDR blocks assigned
  - [ ] Auto-assign public IP disabled
  - [ ] Properly tagged
- [ ] Private database tier subnets created in two AZs
  - [ ] Correct CIDR blocks assigned
  - [ ] Auto-assign public IP disabled
  - [ ] Properly tagged

### Internet Connectivity
- [ ] Internet Gateway created and attached to VPC
- [ ] NAT Gateways created in public subnets
  - [ ] One NAT Gateway per AZ
  - [ ] Elastic IPs allocated
  - [ ] Properly tagged

### Route Tables
- [ ] Public route table configured
  - [ ] Route to Internet Gateway
  - [ ] Associated with public subnets
- [ ] Private route tables configured
  - [ ] Routes to NAT Gateways
  - [ ] Associated with correct private subnets
  - [ ] Separate route tables for each AZ

### VPC Endpoints
- [ ] SSM endpoint created and configured
- [ ] ECR API endpoint created and configured
- [ ] ECR DKR endpoint created and configured
- [ ] S3 Gateway endpoint created and configured
- [ ] Endpoints have appropriate security groups
- [ ] Private DNS enabled where appropriate

## Module 2: Network Access Controls

### Network ACLs
- [ ] Public subnet NACL configured
  - [ ] Inbound HTTP/HTTPS allowed
  - [ ] Return traffic allowed
  - [ ] Default deny all other traffic
- [ ] Web tier NACL configured
  - [ ] Inbound from ALB allowed
  - [ ] Outbound to app tier allowed
  - [ ] Default deny all other traffic
- [ ] App tier NACL configured
  - [ ] Inbound from web tier allowed
  - [ ] Outbound to database tier allowed
  - [ ] Default deny all other traffic
- [ ] Database tier NACL configured
  - [ ] Inbound from app tier allowed
  - [ ] Default deny all other traffic

### Security Groups
- [ ] ALB security group configured
  - [ ] Inbound HTTP/HTTPS from internet
  - [ ] No unnecessary rules
- [ ] Web tier security group configured
  - [ ] Inbound only from ALB
  - [ ] Outbound to app tier only
- [ ] App tier security group configured
  - [ ] Inbound only from web tier
  - [ ] Outbound to database tier only
- [ ] Database tier security group configured
  - [ ] Inbound only from app tier
  - [ ] No unnecessary outbound rules
- [ ] VPC endpoint security group configured
  - [ ] Inbound HTTPS from VPC CIDR
  - [ ] No unnecessary rules

## Module 3: DDoS Protection

### AWS Shield Advanced
- [ ] Shield Advanced subscription active
- [ ] DDoS response team access configured
- [ ] Protected resources registered
- [ ] CloudWatch alarms configured for DDoS events

### AWS WAF
- [ ] Web ACL created and configured
- [ ] AWS managed rule groups enabled:
  - [ ] Core rule set
  - [ ] Known bad inputs
- [ ] Custom rules implemented:
  - [ ] Rate limiting rule
  - [ ] IP reputation rule
- [ ] Logging enabled and configured
- [ ] CloudWatch metrics enabled

## Module 4: Network Monitoring

### VPC Flow Logs
- [ ] Flow logs enabled for VPC
- [ ] CloudWatch log group created
- [ ] IAM role configured with appropriate permissions
- [ ] Log retention period set
- [ ] Log format includes required fields

### GuardDuty
- [ ] GuardDuty enabled in the region
- [ ] Findings configured to publish to EventBridge
- [ ] SNS notifications configured
- [ ] Appropriate IAM permissions set
- [ ] Finding frequency set to 15 minutes

### Monitoring and Alerting
- [ ] CloudWatch metrics configured
- [ ] CloudWatch alarms created for:
  - [ ] Suspicious traffic patterns
  - [ ] Failed VPC endpoint access
  - [ ] Network ACL blocks
  - [ ] Security group violations
- [ ] SNS topics and subscriptions configured
- [ ] EventBridge rules properly set up

## Module 5: Network Security Testing

### Connectivity Testing
- [ ] Bastion host accessible via SSH
- [ ] Web tier can reach app tier
- [ ] App tier can reach database tier
- [ ] Private subnets cannot access internet directly
- [ ] VPC endpoints are accessible

### Security Control Testing
- [ ] WAF rules block inappropriate requests
- [ ] NACLs block unauthorized access
- [ ] Security groups enforce proper segmentation
- [ ] Flow logs capture relevant traffic
- [ ] GuardDuty detects suspicious activity

## Overall Implementation

### Infrastructure Validation
- [ ] All required components are deployed
- [ ] Resources are properly tagged
- [ ] No public access to private resources
- [ ] Defense in depth implemented

### Security Best Practices
- [ ] Least privilege access implemented
- [ ] Network segmentation enforced
- [ ] Encryption in transit enabled
- [ ] Logging and monitoring active
- [ ] No default security groups or NACLs in use

### Monitoring and Alerting
- [ ] All required metrics collected
- [ ] Alerts properly configured
- [ ] Notifications being delivered
- [ ] Logs being captured and stored
- [ ] Audit trail maintained

## Cleanup Validation

After completing the lab cleanup, verify that all resources have been properly deleted:

### Core Infrastructure
- [ ] EC2 instances terminated
- [ ] Security groups deleted
- [ ] NACLs deleted
- [ ] Route tables deleted
- [ ] Subnets deleted
- [ ] VPC endpoints deleted
- [ ] NAT Gateways deleted
- [ ] Internet Gateway detached and deleted
- [ ] VPC deleted

### Security Services
- [ ] WAF Web ACL deleted
- [ ] WAF rule groups deleted
- [ ] Shield Advanced subscription cancelled (if desired)
- [ ] GuardDuty disabled
- [ ] Flow logs disabled

### Supporting Resources
- [ ] CloudWatch log groups deleted
- [ ] CloudWatch alarms deleted
- [ ] SNS topics deleted
- [ ] IAM roles and policies deleted
- [ ] Elastic IPs released

## Next Steps

After completing this validation checklist, consider:

1. Implementing additional security controls
2. Setting up automated compliance checks
3. Creating custom WAF rules for specific threats
4. Enhancing monitoring and alerting
5. Documenting lessons learned and best practices 