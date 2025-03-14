#!/bin/bash

# Deploy script for Lab 8: Infrastructure and Network Protection
# This script deploys the CloudFormation templates in the correct order

set -e

# Configuration
ENVIRONMENT="Lab8"
REGION=$(aws configure get region)
EMAIL_ADDRESS=""
STACK_PREFIX="$ENVIRONMENT"

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
    
    echo -e "${GREEN}Starting deployment of Lab 8 infrastructure...${NC}"
    
    # Deploy VPC and Network Infrastructure
    echo -e "${YELLOW}Deploying network infrastructure...${NC}"
    deploy_stack \
        "${STACK_PREFIX}-network" \
        "../cloudformation/infrastructure.yaml" \
        "ParameterKey=Environment,ParameterValue=$ENVIRONMENT"
    
    # Deploy WAF Configuration
    echo -e "${YELLOW}Deploying WAF configuration...${NC}"
    deploy_stack \
        "${STACK_PREFIX}-waf" \
        "../cloudformation/waf.yaml" \
        "ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
         ParameterKey=RequestThreshold,ParameterValue=2000"
    
    # Deploy Shield Configuration
    echo -e "${YELLOW}Deploying Shield configuration...${NC}"
    deploy_stack \
        "${STACK_PREFIX}-shield" \
        "../cloudformation/shield.yaml" \
        "ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
         ParameterKey=EmailAddress,ParameterValue=$EMAIL_ADDRESS"
    
    # Deploy Monitoring Configuration
    echo -e "${YELLOW}Deploying monitoring configuration...${NC}"
    deploy_stack \
        "${STACK_PREFIX}-monitoring" \
        "../cloudformation/monitoring.yaml" \
        "ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
         ParameterKey=EmailAddress,ParameterValue=$EMAIL_ADDRESS \
         ParameterKey=RetentionDays,ParameterValue=30"
    
    echo -e "${GREEN}Infrastructure deployment completed successfully!${NC}"
    
    # Display important information
    echo -e "\n${YELLOW}Important Information:${NC}"
    echo "1. Check your email to confirm SNS topic subscriptions"
    echo "2. Access the CloudWatch dashboard for monitoring"
    echo "3. Review Security Hub and GuardDuty findings"
    
    # Run security tests
    echo -e "\n${YELLOW}Running security tests...${NC}"
    ALB_URL=$(aws cloudformation describe-stacks \
        --stack-name "${STACK_PREFIX}-network" \
        --query 'Stacks[0].Outputs[?OutputKey==`AlbDnsName`].OutputValue' \
        --output text)
    
    if [ -n "$ALB_URL" ]; then
        python3 network_security_test.py "$ENVIRONMENT" "http://$ALB_URL"
    else
        echo -e "${RED}Could not retrieve ALB URL for testing${NC}"
    fi
}

# Execute main function
main "$@" 