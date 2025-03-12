# Lab 8: Infrastructure and Network Protection - Architecture Diagram

This document provides a visual representation of the secure network infrastructure you'll build in this lab.

## Overall Architecture

```mermaid
graph TB
    subgraph "AWS Cloud"
        subgraph "AWS Shield & WAF"
            Shield[AWS Shield Advanced]
            WAF[AWS WAF]
            Rules[WAF Rules]
        end
        
        subgraph "VPC"
            subgraph "Public Subnet 1"
                ALB[Application Load Balancer]
                Bastion[Bastion Host]
            end
            
            subgraph "Private Subnet 1"
                WebASG[Web Tier ASG]
                NACL1[Network ACL]
                SG1[Security Group]
            end
            
            subgraph "Private Subnet 2"
                AppASG[App Tier ASG]
                NACL2[Network ACL]
                SG2[Security Group]
            end
            
            subgraph "Private Subnet 3"
                RDS[RDS Instance]
                NACL3[Network ACL]
                SG3[Security Group]
            end
            
            subgraph "Network Security"
                FlowLogs[VPC Flow Logs]
                GuardDuty[GuardDuty]
                Endpoints[VPC Endpoints]
            end
        end
        
        subgraph "Monitoring"
            CloudWatch[CloudWatch]
            CloudTrail[CloudTrail]
            SNS[SNS Notifications]
        end
    end
    
    Internet((Internet)) --> Shield
    Shield --> WAF
    WAF --> ALB
    
    ALB --> WebASG
    WebASG --> AppASG
    AppASG --> RDS
    
    Bastion --> WebASG
    Bastion --> AppASG
    
    NACL1 -.-> WebASG
    NACL2 -.-> AppASG
    NACL3 -.-> RDS
    
    SG1 -.-> WebASG
    SG2 -.-> AppASG
    SG3 -.-> RDS
    
    FlowLogs --> CloudWatch
    GuardDuty --> SNS
    
    WebASG --> Endpoints
    AppASG --> Endpoints
```

## Module 1: Secure VPC Design

```mermaid
graph TB
    subgraph "VPC Design"
        subgraph "Availability Zone 1"
            PublicSubnet1[Public Subnet]
            PrivateWeb1[Private Web Subnet]
            PrivateApp1[Private App Subnet]
            PrivateDB1[Private DB Subnet]
            
            IGW[Internet Gateway]
            NGW1[NAT Gateway]
            
            PublicRT1[Public Route Table]
            PrivateRT1[Private Route Table]
        end
        
        subgraph "Availability Zone 2"
            PublicSubnet2[Public Subnet]
            PrivateWeb2[Private Web Subnet]
            PrivateApp2[Private App Subnet]
            PrivateDB2[Private DB Subnet]
            
            NGW2[NAT Gateway]
            
            PublicRT2[Public Route Table]
            PrivateRT2[Private Route Table]
        end
        
        VPCEndpoints[VPC Endpoints]
    end
    
    IGW --> PublicSubnet1
    IGW --> PublicSubnet2
    
    PublicSubnet1 --> NGW1
    PublicSubnet2 --> NGW2
    
    NGW1 --> PrivateWeb1
    NGW1 --> PrivateApp1
    NGW2 --> PrivateWeb2
    NGW2 --> PrivateApp2
    
    PrivateWeb1 --> VPCEndpoints
    PrivateWeb2 --> VPCEndpoints
    PrivateApp1 --> VPCEndpoints
    PrivateApp2 --> VPCEndpoints
```

## Module 2: Network Access Controls

```mermaid
graph TB
    subgraph "Network ACLs"
        NACL_Public[Public Subnet NACL]
        NACL_Web[Web Tier NACL]
        NACL_App[App Tier NACL]
        NACL_DB[DB Tier NACL]
    end
    
    subgraph "Security Groups"
        SG_ALB[ALB Security Group]
        SG_Web[Web Tier Security Group]
        SG_App[App Tier Security Group]
        SG_DB[DB Tier Security Group]
    end
    
    NACL_Public --> SG_ALB
    NACL_Web --> SG_Web
    NACL_App --> SG_App
    NACL_DB --> SG_DB
    
    SG_ALB --> SG_Web
    SG_Web --> SG_App
    SG_App --> SG_DB
```

## Module 3: DDoS Protection

```mermaid
graph TB
    subgraph "DDoS Protection"
        Shield[AWS Shield Advanced]
        WAF[AWS WAF]
        
        subgraph "WAF Rules"
            RateLimit[Rate Limiting]
            IPReputation[IP Reputation]
            SQLi[SQL Injection]
            XSS[Cross-Site Scripting]
            GeoBlock[Geo Blocking]
        end
        
        subgraph "Shield Features"
            Layer3[Layer 3/4 Protection]
            Layer7[Layer 7 Protection]
            DRTSupport[DRT Support]
            CostProtection[Cost Protection]
        end
    end
    
    Shield --> Layer3
    Shield --> Layer7
    Shield --> DRTSupport
    Shield --> CostProtection
    
    WAF --> RateLimit
    WAF --> IPReputation
    WAF --> SQLi
    WAF --> XSS
    WAF --> GeoBlock
```

## Module 4: Network Monitoring

```mermaid
graph TB
    subgraph "Network Monitoring"
        subgraph "Data Collection"
            FlowLogs[VPC Flow Logs]
            GuardDuty[GuardDuty]
            CloudTrail[CloudTrail]
        end
        
        subgraph "Analysis"
            CloudWatch[CloudWatch]
            Athena[Athena]
            Dashboard[Security Dashboard]
        end
        
        subgraph "Alerting"
            SNS[SNS]
            Lambda[Lambda]
            EventBridge[EventBridge]
        end
    end
    
    FlowLogs --> CloudWatch
    FlowLogs --> Athena
    GuardDuty --> EventBridge
    CloudTrail --> CloudWatch
    
    CloudWatch --> Dashboard
    Athena --> Dashboard
    
    EventBridge --> Lambda
    Lambda --> SNS
```

## Module 5: Network Security Testing

```mermaid
graph TB
    subgraph "Security Testing"
        subgraph "Test Cases"
            AccessControl[Access Control Tests]
            DDoSTests[DDoS Simulation]
            WAFTests[WAF Rule Tests]
            MonitoringTests[Monitoring Tests]
        end
        
        subgraph "Validation"
            FlowAnalysis[Flow Log Analysis]
            AlertVerification[Alert Verification]
            MetricsReview[Metrics Review]
        end
        
        subgraph "Documentation"
            TestResults[Test Results]
            SecurityFindings[Security Findings]
            Recommendations[Recommendations]
        end
    end
    
    AccessControl --> FlowAnalysis
    DDoSTests --> AlertVerification
    WAFTests --> MetricsReview
    MonitoringTests --> AlertVerification
    
    FlowAnalysis --> TestResults
    AlertVerification --> SecurityFindings
    MetricsReview --> Recommendations
``` 