# Lab 9: Incident Response and Recovery - Architecture Diagram

This document provides a visual representation of the incident response and recovery framework you'll build in this lab.

## Overall Architecture

```mermaid
graph TB
    subgraph "Detection"
        SecurityHub[AWS Security Hub]
        GuardDuty[GuardDuty]
        Config[AWS Config]
        CloudTrail[CloudTrail]
        CloudWatch[CloudWatch]
    end

    subgraph "Analysis"
        EventBridge[EventBridge]
        AnalysisLambda[Analysis Lambda]
        SecurityLake[Security Lake]
        Athena[Athena]
    end

    subgraph "Response"
        IncidentManager[Systems Manager<br>Incident Manager]
        ResponseLambda[Response Lambda]
        SSM[Systems Manager]
        StepFunctions[Step Functions]
    end

    subgraph "Recovery"
        Backup[AWS Backup]
        DR[Disaster Recovery]
        BackupVault[Backup Vault]
    end

    subgraph "Notification"
        SNS[SNS]
        ChatOps[ChatOps]
        Email[Email]
    end

    SecurityHub --> EventBridge
    GuardDuty --> EventBridge
    Config --> EventBridge
    CloudTrail --> EventBridge
    CloudWatch --> EventBridge

    EventBridge --> AnalysisLambda
    EventBridge --> IncidentManager
    EventBridge --> SNS

    AnalysisLambda --> SecurityLake
    AnalysisLambda --> Athena
    AnalysisLambda --> ResponseLambda

    IncidentManager --> SSM
    IncidentManager --> StepFunctions
    IncidentManager --> SNS

    ResponseLambda --> SSM
    ResponseLambda --> Backup
    ResponseLambda --> DR

    SNS --> ChatOps
    SNS --> Email
```

## Module 1: Incident Response Preparation

```mermaid
graph TB
    subgraph "Detection Setup"
        SecurityHub[Security Hub]
        GuardDuty[GuardDuty]
        Config[AWS Config]
        
        subgraph "Security Standards"
            CIS[CIS Benchmark]
            PCI[PCI DSS]
            Custom[Custom Rules]
        end
    end

    subgraph "Notification Setup"
        SNS[SNS Topics]
        ChatOps[ChatOps Integration]
        Email[Email Notifications]
        
        subgraph "Escalation"
            L1[Level 1 - Analysts]
            L2[Level 2 - Engineers]
            L3[Level 3 - Management]
        end
    end

    subgraph "Forensics Setup"
        S3[Forensics S3 Bucket]
        KMS[KMS Encryption]
        IAM[IAM Roles]
        
        subgraph "Evidence Collection"
            VPC[VPC Flow Logs]
            Logs[CloudWatch Logs]
            Snapshots[EBS Snapshots]
        end
    end

    SecurityHub --> SNS
    GuardDuty --> SNS
    Config --> SNS

    SNS --> ChatOps
    SNS --> Email

    VPC --> S3
    Logs --> S3
    Snapshots --> S3

    S3 --> KMS
    IAM --> S3
```

## Module 2: Detection and Analysis

```mermaid
graph TB
    subgraph "Event Sources"
        SecurityHub[Security Hub]
        GuardDuty[GuardDuty]
        CloudTrail[CloudTrail]
        Config[AWS Config]
    end

    subgraph "Event Processing"
        EventBridge[EventBridge]
        Lambda[Analysis Lambda]
        
        subgraph "Rules"
            Severity[Severity Rules]
            Type[Event Type Rules]
            Resource[Resource Rules]
        end
    end

    subgraph "Analysis"
        SecurityLake[Security Lake]
        Athena[Athena]
        QuickSight[QuickSight]
        
        subgraph "Classification"
            High[High Priority]
            Medium[Medium Priority]
            Low[Low Priority]
        end
    end

    SecurityHub --> EventBridge
    GuardDuty --> EventBridge
    CloudTrail --> EventBridge
    Config --> EventBridge

    EventBridge --> Lambda
    Lambda --> SecurityLake
    SecurityLake --> Athena
    Athena --> QuickSight
```

## Module 3: Containment and Eradication

```mermaid
graph TB
    subgraph "Incident Detection"
        Event[Security Event]
        Analysis[Automated Analysis]
        Classification[Incident Classification]
    end

    subgraph "Automated Response"
        Lambda[Response Lambda]
        StepFunctions[Step Functions]
        SSM[Systems Manager]
        
        subgraph "Actions"
            Isolate[Network Isolation]
            Snapshot[Create Snapshots]
            Block[Block Access]
            Terminate[Terminate Resources]
        end
    end

    subgraph "Manual Response"
        Runbook[Response Runbook]
        Approval[Manual Approval]
        Documentation[Documentation]
    end

    Event --> Analysis
    Analysis --> Classification
    Classification --> Lambda
    Classification --> Runbook

    Lambda --> StepFunctions
    StepFunctions --> SSM
    SSM --> Isolate
    SSM --> Snapshot
    SSM --> Block
    SSM --> Terminate

    Runbook --> Approval
    Approval --> Documentation
```

## Module 4: Recovery and Post-Incident

```mermaid
graph TB
    subgraph "Recovery Planning"
        Assessment[Impact Assessment]
        Plan[Recovery Plan]
        Validation[Recovery Validation]
    end

    subgraph "Recovery Actions"
        Backup[AWS Backup]
        DR[Disaster Recovery]
        
        subgraph "Steps"
            Restore[Restore Resources]
            Configure[Reconfigure Services]
            Verify[Verify Operations]
        end
    end

    subgraph "Post-Incident"
        Analysis[Incident Analysis]
        Report[Incident Report]
        Lessons[Lessons Learned]
        
        subgraph "Improvements"
            Process[Process Updates]
            Controls[Security Controls]
            Training[Team Training]
        end
    end

    Assessment --> Plan
    Plan --> Backup
    Plan --> DR

    Backup --> Restore
    DR --> Restore
    Restore --> Configure
    Configure --> Verify

    Verify --> Analysis
    Analysis --> Report
    Report --> Lessons
    Lessons --> Process
    Lessons --> Controls
    Lessons --> Training
```

## Module 5: Testing and Improvement

```mermaid
graph TB
    subgraph "Testing Framework"
        Scenarios[Test Scenarios]
        Execution[Test Execution]
        Evaluation[Test Evaluation]
    end

    subgraph "Test Types"
        Tabletop[Tabletop Exercise]
        Functional[Functional Test]
        FullScale[Full-Scale Test]
        
        subgraph "Components"
            Detection[Detection Test]
            Response[Response Test]
            Recovery[Recovery Test]
        end
    end

    subgraph "Improvement"
        Results[Test Results]
        Analysis[Gap Analysis]
        Updates[Framework Updates]
        
        subgraph "Areas"
            Automation[Automation]
            Procedures[Procedures]
            Training[Training]
        end
    end

    Scenarios --> Tabletop
    Scenarios --> Functional
    Scenarios --> FullScale

    Tabletop --> Detection
    Functional --> Response
    FullScale --> Recovery

    Detection --> Results
    Response --> Results
    Recovery --> Results

    Results --> Analysis
    Analysis --> Updates
    Updates --> Automation
    Updates --> Procedures
    Updates --> Training
``` 