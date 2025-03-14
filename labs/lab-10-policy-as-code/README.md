# Lab 10: Policy as Code with CI/CD

## Learning Objectives

By completing this lab, you will be able to:

- Implement Policy as Code (PaC) using AWS CloudFormation Guard and AWS CDK
- Create and manage security policies using version control
- Implement CI/CD pipelines for automated policy validation
- Detect and prevent compliance drift using automated checks
- Scale policy management across multiple AWS accounts

## AWS Services Used

- AWS CloudFormation
- AWS Config
- AWS CodePipeline/CodeBuild
- AWS Organizations
- CloudFormation Guard

## Estimated Time to Complete

3-4 hours

## AWS Free Tier Usage

This lab primarily uses services that are included in the AWS Free Tier or have minimal costs:
- AWS CodePipeline: First pipeline is free for 30 days
- AWS CodeBuild: First 100 build minutes per month free
- AWS Config: Free Tier includes basic usage

**Estimated cost if running continuously beyond Free Tier**: $2-7 per day

## Prerequisites

Before starting this lab, you should have:

1. An AWS account with administrator access
2. AWS CLI configured on your local machine
3. Basic familiarity with CI/CD concepts
4. Git installed on your local machine

## Architecture Overview

This lab implements a Policy as Code architecture including:

- Central policy repository in Git
- Automated validation using AWS CloudFormation Guard
- CI/CD pipeline for policy deployment
- Multi-account policy distribution
- Continuous compliance monitoring

## Lab Components

- [Step-by-Step Guide](step-by-step-guide.md) - Detailed implementation instructions
- [Validation Checklist](validation-checklist.md) - Verify your implementation
- [Challenges](challenges.md) - Additional tasks to extend your learning
- [Open Challenges](open-challenges.md) - Open-ended scenarios with creative solutions
- Code implementations:
  - [CloudFormation](code/cloudformation/) - Deploy via CFN templates
  - [Scripts](code/scripts/) - Supporting scripts and automation

## Module Overview

### Module 1: Policy as Code Foundations
Learn about policy as code concepts and set up the foundational infrastructure

### Module 2: Policy Development
Create security policies using CloudFormation Guard and AWS CDK constructs

### Module 3: CI/CD Pipeline for Policies
Set up automated testing and deployment of security policies

### Module 4: Multi-Account Policy Management
Implement cross-account policy distribution and enforcement

### Module 5: Compliance Monitoring
Implement automated compliance monitoring and reporting

## Skills Demonstrated

Completing this lab demonstrates your ability to:

- Implement security policy as code
- Manage policies using version control
- Integrate security controls with CI/CD pipelines
- Scale security policies across environments
- Automate compliance reporting and monitoring
- Document policy controls and their business value

## Next Steps

After completing this lab, we recommend exploring the [Advanced Challenges](../advanced-challenges/) to build on your skills.