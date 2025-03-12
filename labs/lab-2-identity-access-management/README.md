# Lab 2: Identity and Access Management Implementation

## Learning Objectives

By completing this lab, you will be able to:

- Implement AWS IAM best practices and the principle of least privilege
- Design and implement role-based access control (RBAC) for AWS resources
- Configure and use IAM roles for secure cross-account access
- Implement AWS permission boundaries and service control policies (SCPs)
- Create and manage IAM identity providers for federation
- Establish IAM Access Analyzer for permission management

## AWS Services Used

- AWS Identity and Access Management (IAM)
- AWS Organizations (for SCPs)
- AWS IAM Identity Center (formerly AWS SSO)
- AWS IAM Access Analyzer
- AWS Resource Access Manager (RAM)
- AWS CloudTrail (for IAM activity monitoring)

## Estimated Time to Complete

3-4 hours

## AWS Free Tier Usage

This lab primarily uses services that are included in the AWS Free Tier or have minimal costs:
- IAM: Always free
- IAM Identity Center: Free tier includes basic functionality
- IAM Access Analyzer: Always free
- AWS Organizations: Always free

**Estimated cost if running continuously beyond Free Tier**: $0-1 per day

## Prerequisites

Before starting this lab, you should have:

1. Completed [Lab 1: AWS Account Governance](../lab-1-account-governance/)
2. An AWS account with administrator access
3. AWS CLI configured on your local machine
4. Basic understanding of IAM concepts (users, roles, policies)
5. Git installed on your local machine

## Architecture Overview

![Identity and Access Management Architecture](architecture-diagram.png)

This lab implements a comprehensive identity and access management architecture including:

- Centralized identity management with IAM Identity Center
- Role-based access control using IAM roles and policies
- Permission boundaries to limit administrator permissions
- Access analysis with IAM Access Analyzer
- External identity federation

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

### Module 1: IAM Foundations and Best Practices
Implement IAM user management, password policies, and MFA requirements

### Module 2: Role-Based Access Control
Design and implement IAM roles and policies for different job functions

### Module 3: Permission Boundaries and SCPs
Implement guardrails to prevent privilege escalation and resource over-provisioning

### Module 4: Identity Federation
Configure external identity provider integration with AWS

### Module 5: Access Analysis and Monitoring
Implement IAM Access Analyzer and CloudTrail monitoring for IAM activities

## Skills Demonstrated

Completing this lab demonstrates your ability to:

- Implement AWS identity management best practices
- Design secure access control systems using the principle of least privilege
- Configure identity federation for enterprise environments
- Analyze and monitor IAM permissions for security risks
- Use Infrastructure as Code (IaC) for identity and access configurations
- Evaluate access control posture and identify improvements
- Document identity controls and their business value
- Design creative solutions to access management challenges

## Next Steps

After completing this lab, we recommend continuing to [Lab 3: Security Automation with IaC](../lab-3-security-automation-iac/) to build on these foundations. 