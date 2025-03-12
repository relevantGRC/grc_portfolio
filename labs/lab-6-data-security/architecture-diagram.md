# Lab 6: Data Security - Architecture Diagram

This document provides a visual representation of the architecture you'll build in this lab.

## Overall Architecture

```mermaid
graph TD
    subgraph "AWS Cloud"
        subgraph "Data Security Architecture"
            KMS[AWS KMS]
            
            subgraph "Data Storage"
                S3[Encrypted S3 Buckets]
                RDS[Encrypted RDS Database]
                DDB[Encrypted DynamoDB Table]
            end
            
            subgraph "Data Classification"
                Macie[AWS Macie]
                Tags[Resource Tags]
            end
            
            subgraph "Access Control"
                IAM[IAM Policies]
                S3Policy[S3 Bucket Policies]
                RDSPolicy[RDS Access Controls]
            end
            
            subgraph "Monitoring & Auditing"
                CT[CloudTrail]
                CW[CloudWatch]
                SNS[SNS Notifications]
            end
            
            subgraph "Automated Remediation"
                Lambda[Lambda Functions]
                EventBridge[EventBridge Rules]
            end
        end
    end
    
    User[User/Application] -->|Authenticated Access| IAM
    IAM -->|Authorized Access| S3
    IAM -->|Authorized Access| RDS
    IAM -->|Authorized Access| DDB
    
    KMS -->|Encryption Keys| S3
    KMS -->|Encryption Keys| RDS
    KMS -->|Encryption Keys| DDB
    
    S3 -->|Access Logs| CT
    RDS -->|Access Logs| CT
    DDB -->|Access Logs| CT
    
    CT -->|Security Events| CW
    CW -->|Alerts| SNS
    CW -->|Trigger| EventBridge
    
    EventBridge -->|Invoke| Lambda
    Lambda -->|Remediate| S3
    Lambda -->|Remediate| RDS
    Lambda -->|Remediate| DDB
    
    Macie -->|Scan| S3
    Macie -->|Findings| CW
    
    Tags -->|Classify| S3
    Tags -->|Classify| RDS
    Tags -->|Classify| DDB
    
    S3Policy -->|Enforce| S3
    RDSPolicy -->|Enforce| RDS
```

## Module 1: Encryption Foundations

```mermaid
graph TD
    subgraph "Encryption Foundations"
        KMS[AWS KMS]
        CMK1[Customer Managed Key - S3]
        CMK2[Customer Managed Key - RDS]
        CMK3[Customer Managed Key - DynamoDB]
        
        S3[S3 Bucket]
        RDS[RDS Database]
        DDB[DynamoDB Table]
        
        KMSPolicy[KMS Key Policies]
        KeyRotation[Automatic Key Rotation]
    end
    
    KMS -->|Create| CMK1
    KMS -->|Create| CMK2
    KMS -->|Create| CMK3
    
    CMK1 -->|Encrypt| S3
    CMK2 -->|Encrypt| RDS
    CMK3 -->|Encrypt| DDB
    
    KMSPolicy -->|Control Access| CMK1
    KMSPolicy -->|Control Access| CMK2
    KMSPolicy -->|Control Access| CMK3
    
    KeyRotation -->|Enable for| CMK1
    KeyRotation -->|Enable for| CMK2
    KeyRotation -->|Enable for| CMK3
```

## Module 2: Data Classification

```mermaid
graph TD
    subgraph "Data Classification"
        Tags[Resource Tags]
        Macie[AWS Macie]
        
        S3[S3 Buckets]
        RDS[RDS Database]
        DDB[DynamoDB Table]
        
        ClassPolicy[Classification Policies]
        SensitiveData[Sensitive Data Discovery]
    end
    
    Tags -->|Classify| S3
    Tags -->|Classify| RDS
    Tags -->|Classify| DDB
    
    ClassPolicy -->|Define| Tags
    
    Macie -->|Scan| S3
    Macie -->|Discover| SensitiveData
    SensitiveData -->|Update| Tags
```

## Module 3: Secure Access Patterns

```mermaid
graph TD
    subgraph "Secure Access Patterns"
        IAM[IAM Policies]
        S3Policy[S3 Bucket Policies]
        RDSPolicy[RDS Access Controls]
        
        S3[S3 Buckets]
        RDS[RDS Database]
        DDB[DynamoDB Table]
        
        VPC[VPC Endpoints]
        TLS[TLS Encryption]
    end
    
    IAM -->|Control Access| S3
    IAM -->|Control Access| RDS
    IAM -->|Control Access| DDB
    
    S3Policy -->|Enforce| S3
    RDSPolicy -->|Enforce| RDS
    
    VPC -->|Private Access| S3
    VPC -->|Private Access| RDS
    VPC -->|Private Access| DDB
    
    TLS -->|Encrypt Transit| S3
    TLS -->|Encrypt Transit| RDS
    TLS -->|Encrypt Transit| DDB
```

## Module 4: Data Access Monitoring

```mermaid
graph TD
    subgraph "Data Access Monitoring"
        CT[CloudTrail]
        CW[CloudWatch]
        Macie[AWS Macie]
        
        S3[S3 Buckets]
        RDS[RDS Database]
        DDB[DynamoDB Table]
        
        Dashboard[CloudWatch Dashboard]
        Alerts[SNS Alerts]
    end
    
    S3 -->|Data Events| CT
    RDS -->|Data Events| CT
    DDB -->|Data Events| CT
    
    CT -->|Log| CW
    Macie -->|Findings| CW
    
    CW -->|Display| Dashboard
    CW -->|Trigger| Alerts
```

## Module 5: Automated Remediation

```mermaid
graph TD
    subgraph "Automated Remediation"
        CW[CloudWatch]
        EventBridge[EventBridge Rules]
        Lambda[Lambda Functions]
        
        S3[S3 Buckets]
        RDS[RDS Database]
        DDB[DynamoDB Table]
        
        Alerts[SNS Alerts]
    end
    
    CW -->|Trigger| EventBridge
    EventBridge -->|Invoke| Lambda
    
    Lambda -->|Fix Encryption| S3
    Lambda -->|Fix Encryption| RDS
    Lambda -->|Fix Encryption| DDB
    
    Lambda -->|Fix Permissions| S3
    Lambda -->|Fix Permissions| RDS
    Lambda -->|Fix Permissions| DDB
    
    Lambda -->|Send| Alerts
``` 