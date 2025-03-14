# Lab 2: Identity and Access Management - Architecture Diagram

Below is a text representation of the IAM architecture implemented in this lab. For your portfolio, consider creating a proper diagram using tools like draw.io, Lucidchart, or AWS Architecture Icons.

```
┌───────────────────────────────────────────────────────────────────────────┐
│                               AWS Account                                  │
│                                                                           │
│  ┌───────────────┐                 ┌──────────────────────────────────┐   │
│  │               │                 │                                  │   │
│  │ Identity      │                 │  Access Management               │   │
│  │ Sources       │─────────────────▶                                  │   │
│  │               │                 │                                  │   │
│  └───────┬───────┘                 └──────────────┬───────────────────┘   │
│          │                                        │                       │
│  ┌───────▼───────┐                 ┌──────────────▼───────────────────┐   │
│  │               │                 │                                  │   │
│  │ IAM Users     │                 │  IAM Groups                      │   │
│  │ (with MFA)    │                 │  - Developers                    │   │
│  │               │                 │  - Administrators                │   │
│  └───────────────┘                 │  - Security                      │   │
│                                    │                                  │   │
│  ┌───────────────┐                 └──────────────────────────────────┘   │
│  │               │                                                        │
│  │ Federation    │                 ┌──────────────────────────────────┐   │
│  │ (SAML/OIDC)   │                 │                                  │   │
│  │               │                 │  IAM Roles                       │   │
│  └───────────────┘                 │  - EC2Role                       │   │
│                                    │  - LambdaRole                    │   │
│  ┌───────────────┐                 │  - CrossAccountRole              │   │
│  │               │                 │                                  │   │
│  │ Temporary     │                 └──────────────────────────────────┘   │
│  │ Credentials   │                                                        │
│  │               │                 ┌──────────────────────────────────┐   │
│  └───────────────┘                 │                                  │   │
│                                    │  Permission Boundaries           │   │
│                                    │  - DeveloperBoundary             │   │
│                                    │  - ProjectBoundary               │   │
│                                    │                                  │   │
│                                    └──────────────────────────────────┘   │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐   │
│  │                                                                    │   │
│  │  Security Monitoring & Controls                                    │   │
│  │                                                                    │   │
│  │  ┌──────────────┐ ┌────────────────┐ ┌────────────────────┐        │   │
│  │  │              │ │                │ │                    │        │   │
│  │  │ CloudTrail   │ │ CloudWatch     │ │ IAM Access         │        │   │
│  │  │ (API Logs)   │ │ Alarms         │ │ Analyzer           │        │   │
│  │  └──────┬───────┘ └───────┬────────┘ └──────────┬─────────┘        │   │
│  │         │                 │                     │                  │   │
│  │         └─────────────────▼─────────────────────▼──────────────┐  │   │
│  │                                                                │  │   │
│  │                         SNS Notifications                      │  │   │
│  │                         (Security Alerts)                      │  │   │
│  │                                                                │  │   │
│  └────────────────────────────────────────────────────────────────────┘   │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
```

## Security Control Flow

1. **Identity Sources**: Define how users authenticate to AWS
   - IAM Users with enforced MFA
   - Optional federation from external identity providers
   - Temporary credentials for short-term access

2. **Access Management**: Control what resources users can access
   - IAM Groups to organize users by function
   - IAM Roles for services and cross-account access
   - Permission Boundaries to set maximum permissions

3. **Policies and Permissions**: Define specific permissions
   - Custom IAM policies using least privilege
   - AWS managed policies for common use cases
   - Resource-based policies for specific services

4. **Security Monitoring**: Detect unauthorized access attempts
   - CloudTrail logging all API calls
   - CloudWatch alarms for suspicious activities
   - IAM Access Analyzer to identify unintended access

## Design Principles

This architecture follows several key IAM design principles:

- **Least Privilege**: Grant only the permissions needed to perform a task
- **Defense in Depth**: Multiple layers of access controls
- **Separation of Duties**: Different roles for different functions
- **Centralized Identity Management**: Consistent controls across the account
- **Automated Monitoring**: Proactive detection of security issues

## Alternative Architecture Considerations

For enterprise environments, consider these enhancements:

1. **AWS Organizations**: Implement a multi-account strategy with Service Control Policies
2. **AWS IAM Identity Center (SSO)**: Centralized access management across multiple AWS accounts
3. **Attribute-Based Access Control**: Dynamic permissions based on user attributes
4. **Custom Identity Broker**: For complex federation scenarios
5. **Automated Credential Rotation**: Regular rotation of access keys and secrets

## Security Services Coverage

This architecture provides coverage across multiple security domains:

- **Identity Management**: Authentication, MFA, identity federation
- **Access Control**: Authorization, permission boundaries, least privilege
- **Detective Controls**: CloudTrail, CloudWatch, Access Analyzer
- **Incident Response**: Automated alerting for security events
- **Compliance**: Controls mapped to compliance frameworks

## Deployment Strategy

For production environments, consider:

1. **Infrastructure as Code**: Use CloudFormation/CDK to deploy IAM resources
2. **CI/CD Pipeline**: Automated testing and deployment of IAM policies
3. **Version Control**: Track changes to IAM configurations
4. **Policy Validation**: Pre-deployment validation of IAM policies
5. **Access Reviews**: Regular reviews of user permissions