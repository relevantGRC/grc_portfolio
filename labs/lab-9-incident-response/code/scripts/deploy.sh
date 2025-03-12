#!/bin/bash

# Deploy script for Lab 9: Incident Response and Recovery
# This script deploys the CloudFormation templates in the correct order

set -e

# Configuration
ENVIRONMENT="Lab9"
REGION=$(aws configure get region)
EMAIL_ADDRESS=""
STACK_PREFIX="$ENVIRONMENT"
FORENSICS_BUCKET="$ENVIRONMENT-forensics-$(aws sts get-caller-identity --query 'Account' --output text)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check if email is provided
check_email() {
    if [ -z "$EMAIL_ADDRESS" ]; then
        echo -e "${RED}Error: EMAIL_ADDRESS is required for notifications${NC}"
        echo "Usage: $0 <email_address>"
        exit 1
    fi
}

# Function to wait for stack completion
wait_for_stack() {
    local stack_name=$1
    echo -e "${YELLOW}Waiting for stack $stack_name to complete...${NC}"
    
    aws cloudformation wait stack-create-complete \
        --stack-name "$stack_name" \
        --region "$REGION"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Stack $stack_name created successfully${NC}"
    else
        echo -e "${RED}Stack $stack_name creation failed${NC}"
        exit 1
    fi
}

# Function to deploy a CloudFormation stack
deploy_stack() {
    local stack_name=$1
    local template_file=$2
    local parameters=$3
    
    echo -e "${YELLOW}Deploying stack: $stack_name${NC}"
    
    aws cloudformation create-stack \
        --stack-name "$stack_name" \
        --template-body "file://$template_file" \
        --parameters "$parameters" \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "$REGION" \
        --tags Key=Environment,Value="$ENVIRONMENT"
    
    wait_for_stack "$stack_name"
}

# Main deployment process
main() {
    # Validate email address
    check_email
    
    echo -e "${GREEN}Starting deployment of Lab 9 infrastructure...${NC}"
    
    # Deploy incident response framework
    echo -e "${YELLOW}Deploying incident response framework...${NC}"
    deploy_stack \
        "${STACK_PREFIX}-incident-response" \
        "../cloudformation/incident-response.yaml" \
        "ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
         ParameterKey=EmailAddress,ParameterValue=$EMAIL_ADDRESS \
         ParameterKey=ForensicsBucketName,ParameterValue=$FORENSICS_BUCKET"
    
    # Deploy forensics automation
    echo -e "${YELLOW}Deploying forensics automation...${NC}"
    deploy_stack \
        "${STACK_PREFIX}-forensics" \
        "../cloudformation/forensics.yaml" \
        "ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
         ParameterKey=ForensicsBucketName,ParameterValue=$FORENSICS_BUCKET"
    
    echo -e "${GREEN}Infrastructure deployment completed successfully!${NC}"
    
    # Display important information
    echo -e "\n${YELLOW}Important Information:${NC}"
    echo "1. Check your email to confirm SNS topic subscriptions"
    echo "2. The forensics bucket name is: $FORENSICS_BUCKET"
    echo "3. Review the Step Functions workflow in the AWS Console"
    
    # Verify deployment
    echo -e "\n${YELLOW}Verifying deployment...${NC}"
    
    # Check SNS topics
    echo "Checking SNS topics..."
    aws sns list-topics | grep "$ENVIRONMENT"
    
    # Check Lambda functions
    echo "Checking Lambda functions..."
    aws lambda list-functions | grep "$ENVIRONMENT"
    
    # Check Step Functions
    echo "Checking Step Functions state machines..."
    aws stepfunctions list-state-machines | grep "$ENVIRONMENT"
    
    echo -e "\n${GREEN}Deployment verification complete!${NC}"
}

# Execute main function
main "$@" 