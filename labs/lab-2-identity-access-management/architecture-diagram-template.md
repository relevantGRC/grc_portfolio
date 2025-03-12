# Creating a Visual Architecture Diagram for Lab 2

This guide will help you create a professional architecture diagram for your AWS Identity and Access Management implementation.

## Tools for Creating Architecture Diagrams

You can use any of these tools to create your architecture diagram:

1. **Draw.io (diagrams.net)** - Free web-based tool
   - Visit [https://app.diagrams.net/](https://app.diagrams.net/)
   - Use the AWS icon library included in the tool

2. **Lucidchart** - Robust web-based tool (free tier available)
   - Visit [https://www.lucidchart.com](https://www.lucidchart.com)
   - Import the AWS architecture icons

3. **PowerPoint/Keynote** - If you already have these tools
   - Download AWS icon sets (see resources below)

4. **AWS Architecture Icons** - Official AWS icons
   - Download from [https://aws.amazon.com/architecture/icons/](https://aws.amazon.com/architecture/icons/)

## Diagram Components to Include

Your Lab 2 architecture diagram should include these key elements:

### 1. Identity Sources
- AWS IAM Users
- Identity Federation (if implemented)
- SAML Provider (if implemented)
- AWS IAM Identity Center (if implemented)

### 2. Access Management Components
- IAM Groups and their relationships
- IAM Roles and trust relationships
- Permission Boundaries
- Service Control Policies (if using Organizations)

### 3. Policy Structure
- Custom IAM Policies
- AWS Managed Policies in use
- Policy attachment relationships

### 4. Security Controls
- CloudTrail monitoring path
- CloudWatch Alarms
- IAM Access Analyzer
- SNS Notifications

## Sample Layout Guide

Here's a suggested layout for your diagram:

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
│  │               │                 │                                  │   │
│  └───────────────┘                 └──────────────────────────────────┘   │
│                                                                           │
│  ┌───────────────┐                 ┌──────────────────────────────────┐   │
│  │               │                 │                                  │   │
│  │ Federation    │                 │  IAM Roles                       │   │
│  │ (SAML/OIDC)   │                 │                                  │   │
│  │               │                 └──────────────────────────────────┘   │
│  └───────────────┘                                                        │
│                                    ┌──────────────────────────────────┐   │
│  ┌───────────────┐                 │                                  │   │
│  │               │                 │  Permission Boundaries           │   │
│  │ IAM Identity  │                 │                                  │   │
│  │ Center        │                 └──────────────────────────────────┘   │
│  │               │                                                        │
│  └───────────────┘                 ┌──────────────────────────────────┐   │
│                                    │                                  │   │
│                                    │  Service Control Policies        │   │
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
│  │  │              │ │ Alarms         │ │ Analyzer           │        │   │
│  │  └──────┬───────┘ └───────┬────────┘ └──────────┬─────────┘        │   │
│  │         │                 │                     │                  │   │
│  │         └─────────────────▼─────────────────────▼──────────────┐  │   │
│  │                                                                │  │   │
│  │                         SNS Notifications                      │  │   │
│  │                                                                │  │   │
│  └────────────────────────────────────────────────────────────────────┘   │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
```

## Best Practices for Clear Diagrams

1. **Color Coding**
   - Use different colors for different types of IAM resources
   - Example: Identity sources in blue, policies in green, security controls in red

2. **Labels and Annotations**
   - Label each IAM resource with its name
   - Add brief descriptions for key components
   - Include relevant policy attachments and trust relationships

3. **Grouping**
   - Group related IAM resources together
   - Use boundaries to show logical groups
   - Consider grouping by job function or department

4. **Arrows and Flows**
   - Use arrows to show trust relationships
   - Show policy attachment relationships
   - Indicate access flows between roles

## Open-Ended Design Elements

As you create your own architecture diagram, consider adding these elements to demonstrate your understanding:

1. **Multi-Account Structure** - How would you represent IAM resources spanning multiple AWS accounts?

2. **Permission Models** - How would you visualize different permission models (attribute-based, role-based, etc.)?

3. **Automation Components** - How would you include IAM automation components in your diagram?

4. **Governance Controls** - What elements would you add to represent IAM governance processes?

## Example IAM Scenarios to Visualize

Consider how your architecture handles these common IAM scenarios:

1. **Cross-Account Access** - How does a user or role in one account access resources in another?

2. **Federated User Access** - How do users from an external identity provider assume roles?

3. **Temporary Credential Flow** - How are temporary credentials issued and used?

4. **Break-Glass Procedures** - How would emergency access be represented?

5. **Service Roles** - How do AWS services assume roles to perform actions?

## Submission

After creating your architecture diagram:

1. Export it as a PNG or PDF file
2. Place it in the lab-2-identity-access-management directory
3. Update your documentation to reference your visual diagram
4. Consider adding a brief explanation of your design choices

Remember, your architecture diagram should clearly illustrate how your IAM components work together to enforce least privilege and provide secure access to AWS resources. 