# Lab 7: Risk Assessment and Threat Modeling - Architecture Diagram

This document provides a visual representation of the architecture and workflows you'll build in this lab.

## Overall Architecture

```mermaid
graph TD
    subgraph "AWS Cloud"
        subgraph "Risk Assessment Framework"
            TM[Threat Modeling Process]
            RA[Risk Assessment]
            TA[Trusted Advisor]
            SH[Security Hub]
            VP[Vulnerability Prioritization]
            DB[Risk Dashboards]
            
            subgraph "Data Collection"
                CF[AWS Config]
                GD[GuardDuty]
                CT[CloudTrail]
                IAM[IAM Access Analyzer]
                Inspector[Inspector]
            end
            
            subgraph "Risk Processing"
                Lambda[Lambda Functions]
                DDB[DynamoDB Tables]
            end
            
            subgraph "Risk Reporting"
                CW[CloudWatch Dashboards]
                QS[QuickSight]
                SNS[SNS Notifications]
            end
        end
    end
    
    TM -->|Identifies| RA
    RA -->|Feeds into| VP
    TA -->|Provides findings to| RA
    SH -->|Aggregates security findings for| RA
    
    CF -->|Configuration data| RA
    GD -->|Threat findings| RA
    CT -->|Activity logs| RA
    IAM -->|Access findings| RA
    Inspector -->|Vulnerability data| RA
    
    RA -->|Risk data| Lambda
    Lambda -->|Processes and stores| DDB
    DDB -->|Provides data for| DB
    
    DB -->|Visualizes in| CW
    DB -->|Visualizes in| QS
    VP -->|Triggers alerts via| SNS
```

## Module 1: AWS Threat Modeling Methodology

```mermaid
graph TD
    subgraph "Threat Modeling Methodology"
        ST[System Definition]
        TA[Threat Analysis]
        CS[Control Selection]
        VA[Vulnerability Assessment]
        RM[Risk Mitigation]
        
        STRIDE[STRIDE Model]
        DREAD[DREAD Scoring]
        
        TV[Threat Vectors]
        VPC[VPC/Network]
        S3[Data Storage]
        IAM[Identity & Access]
        COMP[Compute]
        API[API Gateway]
    end
    
    ST -->|Define| TV
    TV -->|Analyze using| STRIDE
    STRIDE -->|Score using| DREAD
    
    TA -->|Identify threats to| VPC
    TA -->|Identify threats to| S3
    TA -->|Identify threats to| IAM
    TA -->|Identify threats to| COMP
    TA -->|Identify threats to| API
    
    TA -->|Leads to| CS
    CS -->|Implements| RM
    RM -->|Reduces| VA
```

## Module 2: Service-Specific Risk Assessments

```mermaid
graph TD
    subgraph "Service Risk Assessment"
        S3RA[S3 Risk Assessment]
        RDSRA[RDS Risk Assessment]
        IAMRA[IAM Risk Assessment]
        ECRA[EC2/ECS Risk Assessment]
        LAMBRA[Lambda Risk Assessment]
        
        RT[Risk Templates]
        CAF[AWS CAF]
        
        Risk[Risk Register]
    end
    
    RT -->|Standardizes| S3RA
    RT -->|Standardizes| RDSRA
    RT -->|Standardizes| IAMRA
    RT -->|Standardizes| ECRA
    RT -->|Standardizes| LAMBRA
    
    CAF -->|Security perspective| RT
    
    S3RA -->|Populates| Risk
    RDSRA -->|Populates| Risk
    IAMRA -->|Populates| Risk
    ECRA -->|Populates| Risk
    LAMBRA -->|Populates| Risk
```

## Module 3: AWS Trusted Advisor Integration

```mermaid
graph TD
    subgraph "Trusted Advisor Integration"
        TA[Trusted Advisor]
        Lambda[Lambda Function]
        DDB[DynamoDB Table]
        
        subgraph "Check Categories"
            CS[Cost Optimization]
            PF[Performance]
            SEC[Security]
            FT[Fault Tolerance]
            SO[Service Limits]
        end
        
        subgraph "Automation"
            CF[CloudFormation]
            EventBridge[EventBridge]
            SNS[SNS Topic]
        end
    end
    
    TA -->|Security checks| SEC
    TA -->|Performance checks| PF
    TA -->|Cost checks| CS
    TA -->|Fault tolerance checks| FT
    TA -->|Service limit checks| SO
    
    SEC -->|High-risk findings| EventBridge
    EventBridge -->|Triggers| Lambda
    Lambda -->|Stores findings in| DDB
    Lambda -->|Sends alerts via| SNS
    
    CF -->|Deploys| Lambda
    CF -->|Configures| EventBridge
    CF -->|Creates| DDB
    CF -->|Sets up| SNS
```

## Module 4: Vulnerability Prioritization

```mermaid
graph TD
    subgraph "Vulnerability Prioritization"
        CVSS[CVSS Scoring]
        BA[Business Impact]
        TA[Threat Intelligence]
        
        SC[Scoring System]
        PF[Prioritization Framework]
        
        DDB[DynamoDB]
        Lambda[Lambda Function]
    end
    
    CVSS -->|Technical severity| SC
    BA -->|Business context| SC
    TA -->|Threat context| SC
    
    SC -->|Feeds| PF
    PF -->|Categorizes as| HC[High Criticality]
    PF -->|Categorizes as| MC[Medium Criticality]
    PF -->|Categorizes as| LC[Low Criticality]
    
    Lambda -->|Processes vulnerabilities with| SC
    Lambda -->|Stores results in| DDB
```

## Module 5: Risk Dashboards and Reporting

```mermaid
graph TD
    subgraph "Risk Dashboards and Reporting"
        DDB[DynamoDB]
        Lambda[Lambda Functions]
        
        subgraph "Visualization"
            CW[CloudWatch Dashboard]
            QS[QuickSight]
        end
        
        subgraph "Reports"
            Exec[Executive Summary]
            Tech[Technical Details]
            TR[Trend Reports]
        end
        
        subgraph "Automation"
            EventBridge[EventBridge]
            S3[S3 Bucket]
        end
    end
    
    DDB -->|Provides data for| Lambda
    Lambda -->|Processes data for| CW
    Lambda -->|Prepares data for| QS
    
    CW -->|Visualizes| TR
    QS -->|Generates| Exec
    QS -->|Generates| Tech
    
    EventBridge -->|Schedules| Lambda
    Lambda -->|Stores reports in| S3
``` 