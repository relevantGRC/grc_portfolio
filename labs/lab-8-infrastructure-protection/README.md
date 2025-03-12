# Lab 8: Infrastructure and Network Protection

## Overview

This lab focuses on implementing comprehensive infrastructure and network protection in AWS. You will learn how to design and implement secure network architectures, configure network access controls, protect against DDoS attacks, and monitor network traffic for security threats.

## Learning Objectives

By completing this lab, you will be able to:

1. Design and implement secure VPC architectures
2. Configure and manage Network ACLs and security groups effectively
3. Implement AWS Shield and AWS WAF for DDoS protection
4. Design resilient architectures that can withstand network-based attacks
5. Set up network traffic monitoring and analysis
6. Implement network security best practices

## Prerequisites

Before starting this lab, you should have:

- An AWS account with administrative access
- AWS CLI installed and configured
- Basic understanding of networking concepts
- Familiarity with VPC, subnets, and routing
- Completed Lab 1: AWS Account Governance (recommended)
- Completed Lab 2: Identity and Access Management (recommended)

## Estimated Time and Cost

- **Time to complete**: 4-5 hours
- **AWS cost**: $10-20 if resources are promptly cleaned up after the lab
  - Most resources are eligible for AWS Free Tier
  - AWS WAF and Shield may incur additional charges
  - VPC endpoints and NAT Gateways will incur charges

## Architecture Overview

This lab will guide you through building a secure network infrastructure that includes:

- Multi-tier VPC architecture with public and private subnets
- Network ACLs and security groups for defense in depth
- VPC endpoints for secure AWS service access
- AWS WAF configuration with custom rules
- AWS Shield Advanced protection
- Network traffic monitoring with VPC Flow Logs
- GuardDuty for network threat detection

See the [architecture diagram](architecture-diagram.md) for a visual representation of the solution.

## Modules

The lab is divided into five modules:

1. **Module 1: Secure VPC Design** - Implement a secure multi-tier VPC architecture
2. **Module 2: Network Access Controls** - Configure NACLs and security groups
3. **Module 3: DDoS Protection** - Set up AWS Shield and AWS WAF
4. **Module 4: Network Monitoring** - Implement VPC Flow Logs and GuardDuty
5. **Module 5: Network Security Testing** - Validate network security controls

Follow the [step-by-step guide](step-by-step-guide.md) to complete each module.

## Validation

After completing the lab, use the [validation checklist](validation-checklist.md) to verify your implementation meets all security requirements.

## Advanced Challenges

Once you've completed the main lab, try the [advanced challenges](challenges.md) to further enhance your skills.

## Cleanup

To avoid ongoing charges, make sure to delete all resources created during this lab by following the cleanup instructions at the end of the step-by-step guide.

## Additional Resources

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
- [AWS WAF Documentation](https://docs.aws.amazon.com/waf/latest/developerguide/what-is-aws-waf.html)
- [AWS Shield Documentation](https://docs.aws.amazon.com/waf/latest/developerguide/shield-chapter.html)
- [VPC Flow Logs Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [AWS Network Security Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html) 