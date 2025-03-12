# Lab 3: Security Automation with Infrastructure as Code

## Learning Objectives

By completing this lab, you will be able to:

- Implement security controls as code using CloudFormation and Terraform
- Create secure infrastructure templates with built-in security guardrails
- Implement automated compliance validation for infrastructure
- Develop CI/CD pipelines with security checks
- Write custom policy as code for security enforcement
- Create automated security remediation workflows

## AWS Services Used

- AWS CloudFormation
- AWS CodePipeline and CodeBuild
- AWS Config
- AWS Lambda
- Amazon EventBridge
- Amazon SNS
- AWS Identity and Access Management (IAM)
- AWS Systems Manager

## Estimated Time to Complete

3-4 hours

## AWS Free Tier Usage

This lab primarily uses services that are included in the AWS Free Tier or have minimal costs:
- AWS CloudFormation: Always free
- AWS Lambda: Free tier includes 1 million requests per month
- AWS CodeBuild: Free tier includes 100 build minutes per month
- AWS Config: Free tier includes 5 rules per month

**Estimated cost if running continuously beyond Free Tier**: $1-5 per day depending on the frequency of deployments and the volume of resources created

## Prerequisites

Before starting this lab, you should have:

1. Completed [Lab 1: AWS Account Governance](../lab-1-account-governance/) and [Lab 2: Identity and Access Management](../lab-2-identity-access-management/)
2. An AWS account with administrator access
3. AWS CLI configured on your local machine
4. Git installed on your local machine
5. Basic understanding of CloudFormation and Terraform
6. (Recommended) Terraform CLI installed for Terraform-based exercises

## Architecture Overview

![Security Automation with IaC Architecture](architecture-diagram.png)

This lab implements a comprehensive security automation architecture including:

- Secure baseline infrastructure templates
- CI/CD pipeline with security checks
- Automated compliance validation
- Security remediation workflows
- Policy as code for infrastructure validation

## Lab Components

- [Step-by-Step Guide](step-by-step-guide.md) - Detailed implementation instructions
- [Validation Checklist](validation-checklist.md) - Verify your implementation
- [Challenges](challenges.md) - Additional tasks to extend your learning
- [Open Challenges](open-challenges.md) - Open-ended scenarios with creative solutions
- [Assessment Worksheet](assessment-worksheet.md) - Document your implementation and reflections
- [Architecture Diagram Template](architecture-diagram-template.md) - Guide for creating visual diagrams
- Code implementations:
  - [CloudFormation](code/cloudformation/) - Deploy via CFN templates
  - [Terraform](code/terraform/) - Deploy via Terraform
  - [Scripts](code/scripts/) - Supporting scripts and automation

## Module Overview

### Module 1: Security Controls as Code
Implement baseline security controls using infrastructure as code templates

### Module 2: Automated Compliance Validation
Create automated checks for security compliance in your infrastructure

### Module 3: CI/CD Pipeline with Security Checks
Implement a CI/CD pipeline for infrastructure that includes security validation

### Module 4: Security Remediation Automation
Create automated workflows to remediate security issues

### Module 5: Policy as Code
Implement policy as code solutions for ongoing infrastructure validation

## Skills Demonstrated

Completing this lab demonstrates your ability to:

- Implement security controls through Infrastructure as Code
- Automate security compliance validation
- Integrate security into CI/CD pipelines
- Write policies as code for security enforcement
- Create automated remediation workflows
- Apply DevSecOps principles to infrastructure deployment
- Design secure baseline infrastructure templates
- Enforce security guardrails through automation

## Next Steps

After completing this lab, we recommend continuing to [Lab 4: Compliance Automation](../lab-4-compliance-automation/) to build on these foundations. 