# Lab 3: Security Automation with Infrastructure as Code - Validation Checklist

This validation checklist will help you verify that you've successfully completed all the exercises in Lab 3. Check off each item as you confirm your implementation meets the requirements.

## Module 1: Security Controls as Code

### VPC Security Implementation
- [ ] Created the secure VPC CloudFormation template with the following features:
  - [ ] Public and private subnets
  - [ ] Network ACLs with appropriate rules
  - [ ] Security groups with least privilege principles
  - [ ] VPC flow logs configured
  - [ ] NAT Gateway properly configured

### S3 Bucket Security Implementation
- [ ] Created a Terraform configuration for a secure S3 bucket:
  - [ ] Enabled server-side encryption (SSE-KMS with customer-managed key)
  - [ ] Applied public access blocks
  - [ ] Configured versioning
  - [ ] Set up access logging to a separate bucket
  - [ ] Added lifecycle policies to manage object retention
  - [ ] Configured bucket policy to enforce HTTPS

### Security Baseline Implementation
- [ ] Deployed the CloudFormation template for security baseline:
  - [ ] Template successfully deployed without errors
  - [ ] AWS Config enabled to monitor resources
  - [ ] AWS SecurityHub enabled
  - [ ] AWS Config Rules deployed for common security checks
  - [ ] CloudTrail enabled with appropriate settings

## Module 2: Automated Compliance Validation

### Custom AWS Config Rule
- [ ] Created a custom AWS Config rule that:
  - [ ] Correctly checks for EBS volume encryption
  - [ ] Identifies non-compliant resources
  - [ ] Runs on both configuration changes and on a schedule

### AWS Security Hub Integration
- [ ] Enabled AWS Security Hub:
  - [ ] CIS AWS Foundations Benchmark standard enabled
  - [ ] AWS Foundational Security Best Practices standard enabled
  - [ ] PCI DSS standard enabled (if applicable)
  - [ ] Verified Security Hub is collecting findings

### CloudFormation Template Scanning with cfn-nag
- [ ] Successfully ran cfn-nag against CloudFormation templates:
  - [ ] Identified any security issues in the templates
  - [ ] Resolved high-severity issues
  - [ ] Documented any acceptable risk exceptions

## Module 3: CI/CD Pipeline with Security Checks

### CodePipeline Setup
- [ ] Created a CI/CD pipeline with CodePipeline:
  - [ ] Source stage connected to CodeCommit repository
  - [ ] Build stage with security scanning
  - [ ] Test stage with validation
  - [ ] Pipeline successfully processes template changes

### Security Scanning in CodeBuild
- [ ] Implemented security scanning in the CI/CD pipeline:
  - [ ] cfn-nag scanning added to the build process
  - [ ] Build fails on critical security issues
  - [ ] Scan results are documented

### Security Dashboard
- [ ] Created a security dashboard:
  - [ ] CloudWatch dashboard shows security metrics
  - [ ] Dashboard includes compliance status
  - [ ] Dashboard includes security scan results

## Module 4: Security Remediation Automation

### Auto-Remediation Lambda Function
- [ ] Created a Lambda function that:
  - [ ] Remediates non-compliant resources
  - [ ] Has appropriate IAM permissions
  - [ ] Logs actions for auditing

### EventBridge Rules for Security Events
- [ ] Set up EventBridge rules that:
  - [ ] Trigger on Config rule non-compliance events
  - [ ] Invoke the remediation Lambda function
  - [ ] Send notifications for security events

### Terraform Remediation Module
- [ ] Created a Terraform module that:
  - [ ] Can be reused for security remediation
  - [ ] Follows security best practices
  - [ ] Is properly documented

## Module 5: Policy as Code

### AWS Config Conformance Packs
- [ ] Deployed a Config Conformance Pack:
  - [ ] Pack includes relevant security controls
  - [ ] Compliance status shows in the AWS Config console
  - [ ] Documented any non-compliant resources

### Service Control Policies (SCPs)
- [ ] Created Service Control Policies that:
  - [ ] Enforce security guardrails
  - [ ] Prevent modification of security controls
  - [ ] Follow least privilege principles

### CloudFormation Guard
- [ ] Implemented CloudFormation Guard:
  - [ ] Created policy rules for security best practices
  - [ ] Validated templates against policy rules
  - [ ] Integrated Guard into the development workflow

## Overall Verification

### Resource Validation
- [ ] All AWS resources are deployed as expected
- [ ] No unexpected or unmanaged resources exist
- [ ] Resources are properly tagged

### Compliance Status
- [ ] AWS Config shows compliant status for rules
- [ ] Security Hub shows acceptable compliance score
- [ ] No critical security findings remain unaddressed

### Documentation
- [ ] All implementation choices are documented
- [ ] Exceptions to security best practices are justified and documented
- [ ] README files are complete and accurate

## Final Steps
1. Take screenshots of:
   - AWS Config compliance dashboard
   - Security Hub findings
   - CI/CD pipeline execution results
   - CloudWatch security dashboard

2. Submit these artifacts along with your completed validation checklist.

Congratulations on completing Lab 3: Security Automation with Infrastructure as Code! 