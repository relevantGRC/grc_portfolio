#!/bin/bash

# setup-security-cicd.sh
# Script to set up a CI/CD pipeline with security checks for CloudFormation templates

set -e

# Default values
AWS_REGION="us-east-1"
STACK_NAME="security-cicd-pipeline"
REPO_NAME="security-iac-repo"
BRANCH_NAME="main"
CFN_TEMPLATE_DIR="../cloudformation"
ARTIFACT_BUCKET_NAME=""

# Display help
function show_help {
    echo "Usage: $0 [options]"
    echo "Set up a CI/CD pipeline with security scanning for CloudFormation templates"
    echo ""
    echo "Options:"
    echo "  -r, --region REGION           AWS region (default: us-east-1)"
    echo "  -s, --stack STACK_NAME        CloudFormation stack name (default: security-cicd-pipeline)"
    echo "  -n, --repo REPO_NAME          CodeCommit repository name (default: security-iac-repo)"
    echo "  -b, --branch BRANCH_NAME      Repository branch name (default: main)"
    echo "  -d, --template-dir DIR        Directory containing CloudFormation templates (default: ../cloudformation)"
    echo "  -h, --help                    Display this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -r|--region)
            AWS_REGION="$2"
            shift
            shift
            ;;
        -s|--stack)
            STACK_NAME="$2"
            shift
            shift
            ;;
        -n|--repo)
            REPO_NAME="$2"
            shift
            shift
            ;;
        -b|--branch)
            BRANCH_NAME="$2"
            shift
            shift
            ;;
        -d|--template-dir)
            CFN_TEMPLATE_DIR="$2"
            shift
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

echo "Setting up a CI/CD pipeline with security checks for CloudFormation templates..."
echo "AWS Region: $AWS_REGION"
echo "Stack Name: $STACK_NAME"
echo "Repository Name: $REPO_NAME"
echo "Branch Name: $BRANCH_NAME"
echo "Template Directory: $CFN_TEMPLATE_DIR"

# Check if the repository already exists
REPO_EXISTS=$(aws codecommit get-repository --repository-name "$REPO_NAME" --region "$AWS_REGION" 2>/dev/null || echo "false")
if [ "$REPO_EXISTS" == "false" ]; then
    echo "Creating CodeCommit repository: $REPO_NAME"
    aws codecommit create-repository \
        --repository-name "$REPO_NAME" \
        --repository-description "Repository for secure infrastructure as code" \
        --region "$AWS_REGION"
else
    echo "CodeCommit repository $REPO_NAME already exists. Skipping creation."
fi

# Create an S3 bucket for artifacts if not provided
if [ -z "$ARTIFACT_BUCKET_NAME" ]; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ARTIFACT_BUCKET_NAME="${STACK_NAME}-artifacts-${ACCOUNT_ID}-${AWS_REGION}"
    
    # Check if bucket exists
    BUCKET_EXISTS=$(aws s3api head-bucket --bucket "$ARTIFACT_BUCKET_NAME" 2>/dev/null && echo "true" || echo "false")
    if [ "$BUCKET_EXISTS" == "false" ]; then
        echo "Creating S3 bucket for pipeline artifacts: $ARTIFACT_BUCKET_NAME"
        
        # Create bucket (different commands for us-east-1 and other regions)
        if [ "$AWS_REGION" == "us-east-1" ]; then
            aws s3api create-bucket \
                --bucket "$ARTIFACT_BUCKET_NAME" \
                --region "$AWS_REGION"
        else
            aws s3api create-bucket \
                --bucket "$ARTIFACT_BUCKET_NAME" \
                --region "$AWS_REGION" \
                --create-bucket-configuration LocationConstraint="$AWS_REGION"
        fi
        
        # Enable encryption and block public access
        aws s3api put-bucket-encryption \
            --bucket "$ARTIFACT_BUCKET_NAME" \
            --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
        
        aws s3api put-public-access-block \
            --bucket "$ARTIFACT_BUCKET_NAME" \
            --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    else
        echo "S3 bucket $ARTIFACT_BUCKET_NAME already exists. Skipping creation."
    fi
fi

# Create a temporary directory for the CloudFormation template
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Create CloudFormation template for the pipeline
cat > "$TEMP_DIR/cicd-pipeline.yaml" << EOF
AWSTemplateFormatVersion: '2010-09-09'
Description: 'CI/CD Pipeline with Security Checks for CloudFormation Templates'

Parameters:
  CodeCommitRepositoryName:
    Type: String
    Default: ${REPO_NAME}
    Description: Name of the CodeCommit repository
    
  RepositoryBranchName:
    Type: String
    Default: ${BRANCH_NAME}
    Description: Name of the repository branch
    
  ArtifactBucketName:
    Type: String
    Default: ${ARTIFACT_BUCKET_NAME}
    Description: Name of the S3 bucket for pipeline artifacts

Resources:
  # IAM Roles for Pipeline services
  CodeBuildServiceRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: codebuild.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
      Policies:
        - PolicyName: CodeBuildServicePolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - logs:CreateLogGroup
                  - logs:CreateLogStream
                  - logs:PutLogEvents
                Resource: '*'
              - Effect: Allow
                Action:
                  - s3:GetObject
                  - s3:GetObjectVersion
                  - s3:PutObject
                Resource:
                  - !Sub arn:aws:s3:::\${ArtifactBucketName}/*
              - Effect: Allow
                Action:
                  - cloudformation:ValidateTemplate
                Resource: '*'

  CodePipelineServiceRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: codepipeline.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AWSCodeStarFullAccess
      Policies:
        - PolicyName: CodePipelineServicePolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - s3:GetObject
                  - s3:GetObjectVersion
                  - s3:PutObject
                  - s3:GetBucketVersioning
                Resource:
                  - !Sub arn:aws:s3:::\${ArtifactBucketName}
                  - !Sub arn:aws:s3:::\${ArtifactBucketName}/*
              - Effect: Allow
                Action:
                  - codecommit:GetBranch
                  - codecommit:GetCommit
                  - codecommit:UploadArchive
                  - codecommit:GetUploadArchiveStatus
                  - codecommit:CancelUploadArchive
                Resource: !Sub arn:aws:codecommit:\${AWS::Region}:\${AWS::AccountId}:\${CodeCommitRepositoryName}
              - Effect: Allow
                Action:
                  - codebuild:StartBuild
                  - codebuild:BatchGetBuilds
                Resource: '*'

  # Security scanning with cfn-nag
  SecurityScanningProject:
    Type: AWS::CodeBuild::Project
    Properties:
      Name: cfn-security-scanning
      Description: 'Scan CloudFormation templates for security issues'
      ServiceRole: !GetAtt CodeBuildServiceRole.Arn
      Artifacts:
        Type: CODEPIPELINE
      Environment:
        Type: LINUX_CONTAINER
        ComputeType: BUILD_GENERAL1_SMALL
        Image: aws/codebuild/amazonlinux2-x86_64-standard:4.0
        PrivilegedMode: false
      Source:
        Type: CODEPIPELINE
        BuildSpec: |
          version: 0.2
          phases:
            install:
              runtime-versions:
                ruby: 3.1
              commands:
                - echo "Installing cfn-nag for CloudFormation security scanning"
                - gem install cfn-nag
            build:
              commands:
                - echo "Running security scan on CloudFormation templates"
                - mkdir -p scan-results
                - for template in $(find . -name "*.yaml" -o -name "*.yml" -o -name "*.json" | grep -v "buildspec.yml"); do
                - echo "Scanning template: $template"
                - cfn_nag_scan --input-path "$template" --output-format txt > "scan-results/$(basename "$template").txt" || true
                - done
                - echo "Creating summary report"
                - cat scan-results/*.txt > scan-results/summary.txt
            post_build:
              commands:
                - echo "Security scanning completed on $(date)"
                - if grep -q -i "failures\|warnings" scan-results/summary.txt; then
                - echo "Security issues found. Please review the scan results."
                - cat scan-results/summary.txt
                - echo "Pipeline will continue, but please address security issues."
                - else
                - echo "No security issues found."
                - fi
          artifacts:
            files:
              - scan-results/**/*
              - '**/*.yaml'
              - '**/*.yml'
              - '**/*.json'
              - '**/*.template'
            discard-paths: no

  # CloudFormation validation
  CfnValidationProject:
    Type: AWS::CodeBuild::Project
    Properties:
      Name: cfn-validation
      Description: 'Validate CloudFormation templates'
      ServiceRole: !GetAtt CodeBuildServiceRole.Arn
      Artifacts:
        Type: CODEPIPELINE
      Environment:
        Type: LINUX_CONTAINER
        ComputeType: BUILD_GENERAL1_SMALL
        Image: aws/codebuild/amazonlinux2-x86_64-standard:4.0
        PrivilegedMode: false
      Source:
        Type: CODEPIPELINE
        BuildSpec: |
          version: 0.2
          phases:
            build:
              commands:
                - echo "Validating CloudFormation templates"
                - mkdir -p validation-results
                - for template in $(find . -name "*.yaml" -o -name "*.yml" -o -name "*.json" | grep -v "buildspec.yml"); do
                - echo "Validating template: $template"
                - aws cloudformation validate-template --template-body file://$template > "validation-results/$(basename "$template").json" || echo "Template $template is invalid" >> validation-errors.txt
                - done
            post_build:
              commands:
                - echo "Template validation completed on $(date)"
                - if [ -f validation-errors.txt ]; then
                - echo "Some templates failed validation:"
                - cat validation-errors.txt
                - exit 1
                - else
                - echo "All templates are valid."
                - fi
          artifacts:
            files:
              - validation-results/**/*
              - '**/*.yaml'
              - '**/*.yml'
              - '**/*.json'
              - '**/*.template'
            discard-paths: no

  # CI/CD Pipeline
  Pipeline:
    Type: AWS::CodePipeline::Pipeline
    Properties:
      RoleArn: !GetAtt CodePipelineServiceRole.Arn
      ArtifactStore:
        Type: S3
        Location: !Ref ArtifactBucketName
      Stages:
        - Name: Source
          Actions:
            - Name: Source
              ActionTypeId:
                Category: Source
                Owner: AWS
                Provider: CodeCommit
                Version: '1'
              Configuration:
                RepositoryName: !Ref CodeCommitRepositoryName
                BranchName: !Ref RepositoryBranchName
              OutputArtifacts:
                - Name: SourceCode
        
        - Name: SecurityScan
          Actions:
            - Name: cfn-nag-scan
              ActionTypeId:
                Category: Build
                Owner: AWS
                Provider: CodeBuild
                Version: '1'
              Configuration:
                ProjectName: !Ref SecurityScanningProject
              InputArtifacts:
                - Name: SourceCode
              OutputArtifacts:
                - Name: SecurityScanOutput
        
        - Name: Validate
          Actions:
            - Name: cfn-validate
              ActionTypeId:
                Category: Build
                Owner: AWS
                Provider: CodeBuild
                Version: '1'
              Configuration:
                ProjectName: !Ref CfnValidationProject
              InputArtifacts:
                - Name: SourceCode
              OutputArtifacts:
                - Name: ValidationOutput

  # CloudWatch Event Rule to monitor pipeline status
  PipelineStatusChangeRule:
    Type: AWS::Events::Rule
    Properties:
      Name: !Sub ${AWS::StackName}-pipeline-status-change
      Description: Monitor pipeline state changes
      EventPattern:
        source:
          - aws.codepipeline
        detail-type:
          - CodePipeline Pipeline Execution State Change
        detail:
          pipeline:
            - !Ref Pipeline
      State: ENABLED
      Targets:
        - Arn: !Ref PipelineStatusTopic
          Id: PipelineStatusTopic

  # SNS Topic for notifications
  PipelineStatusTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: !Sub ${AWS::StackName}-pipeline-status-notifications
      DisplayName: Security Pipeline Status Notifications

Outputs:
  PipelineUrl:
    Description: URL to the CodePipeline console
    Value: !Sub https://console.aws.amazon.com/codepipeline/home?region=${AWS::Region}#/view/${Pipeline}
  
  RepositoryUrl:
    Description: URL to the CodeCommit repository
    Value: !Sub https://console.aws.amazon.com/codecommit/home?region=${AWS::Region}#/repository/${CodeCommitRepositoryName}/browse
  
  NotificationTopicArn:
    Description: ARN of the SNS notification topic
    Value: !Ref PipelineStatusTopic
EOF

# Deploy the CloudFormation stack
echo "Deploying CloudFormation stack: $STACK_NAME"
aws cloudformation deploy \
    --template-file "$TEMP_DIR/cicd-pipeline.yaml" \
    --stack-name "$STACK_NAME" \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
        CodeCommitRepositoryName="$REPO_NAME" \
        RepositoryBranchName="$BRANCH_NAME" \
        ArtifactBucketName="$ARTIFACT_BUCKET_NAME" \
    --region "$AWS_REGION"

# Get the CodeCommit clone URL
CLONE_URL=$(aws codecommit get-repository --repository-name "$REPO_NAME" --region "$AWS_REGION" --query 'repositoryMetadata.cloneUrlHttp' --output text)

# Get the stack outputs
PIPELINE_URL=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" --query "Stacks[0].Outputs[?OutputKey=='PipelineUrl'].OutputValue" --output text)
REPO_URL=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" --query "Stacks[0].Outputs[?OutputKey=='RepositoryUrl'].OutputValue" --output text)
TOPIC_ARN=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" --query "Stacks[0].Outputs[?OutputKey=='NotificationTopicArn'].OutputValue" --output text)

echo ""
echo "CI/CD pipeline with security checks has been set up successfully!"
echo "-------------------------------------------------------------------------"
echo "CodeCommit Repository: $REPO_NAME"
echo "Repository URL: $REPO_URL"
echo "Clone URL: $CLONE_URL"
echo ""
echo "Pipeline URL: $PIPELINE_URL"
echo "SNS Topic ARN: $TOPIC_ARN"
echo ""
echo "To start using the pipeline:"
echo "1. Clone the repository: git clone $CLONE_URL"
echo "2. Add your CloudFormation templates to the repository"
echo "3. Push your changes to trigger the pipeline"
echo "4. Subscribe to the SNS topic for notifications: $TOPIC_ARN"
echo "-------------------------------------------------------------------------" 