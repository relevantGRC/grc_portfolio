# AWS Security Labs for GRC Professionals

This directory contains hands-on labs designed to help GRC professionals build and demonstrate practical AWS security implementation skills. Each lab covers a specific domain aligned with the AWS Well-Architected Framework Security Pillar.

## Available Labs

1. [**Lab 1: AWS Account Governance**](lab-1-account-governance/) - Implement foundational security controls for AWS accounts
2. [**Lab 2: Identity and Access Management**](lab-2-identity-access-management/) - Implement role-based access, permission boundaries, identity federation, and access monitoring
3. [**Lab 3: Security Automation with IaC**](lab-3-security-automation-iac/) - Build secure infrastructure using CloudFormation
4. [**Lab 4: Security Monitoring and Incident Response**](lab-4-security-monitoring-incident-response/) - Implement comprehensive security monitoring and automated incident response
5. [**Lab 5: Compliance Automation**](lab-5-compliance-automation/) - Implement automated compliance controls and reporting
6. [**Lab 6: Data Security**](lab-6-data-security/) - Protect data at rest and in transit
7. [**Lab 7: Risk Assessment**](lab-7-risk-threat-modeling/) - Implement threat modeling and risk assessment processes
8. [**Lab 8: Infrastructure Protection**](lab-8-infrastructure-protection/) - Secure VPCs, networks, and compute resources
9. [**Lab 9: Incident Response**](lab-9-incident-response/) - Implement incident response procedures
10. [**Lab 10: Policy as Code**](lab-10-policy-as-code/) - Implementation of scalable policy management via CI/CD

## Lab Structure

Each lab follows a consistent structure:

- **README.md** - Overview and objectives
- **step-by-step-guide.md** - Detailed implementation instructions
- **validation-checklist.md** - How to verify your implementation
- **challenges.md** - Additional tasks to extend your learning
- **code/** - Implementation code in CloudFormation and scripts

## Prerequisites

Before starting any lab, ensure you have:

1. An AWS account (most labs can use the AWS Free Tier)
2. AWS CLI installed and configured
3. Basic familiarity with AWS services
4. Git installed to clone this repository

## Cost Considerations

Each lab includes estimated costs for the AWS resources deployed. Most labs are designed to use AWS Free Tier resources where possible, but some advanced labs may incur charges if resources are left running. Always follow the cleanup instructions at the end of each lab to avoid unexpected charges.

## Learning Path

For those new to AWS security, we recommend following the labs in numerical order as they build upon each other. More experienced users can choose labs based on their interests or skill gaps.

The recommended learning path is:

1. Start with Lab 1 to establish account security foundations
2. Progress through Labs 2-5 to build core security skills
3. Move on to Labs 6-9 for more advanced security implementations
4. Explore Lab 10 to learn about Policy as Code implementation
5. Complete the [Advanced Challenges](../advanced-challenges/) to integrate multiple security domains

## Getting Help

If you encounter issues with any lab:

1. Check the troubleshooting section included in each lab
2. Review the AWS documentation for the relevant services
3. Open an issue in this repository with details of your problem
4. Join our community discussions for peer support

## Contributing

We welcome improvements to existing labs and contributions of new labs. See our [CONTRIBUTING.md](../CONTRIBUTING.md) file for guidelines.

Happy learning and building! 