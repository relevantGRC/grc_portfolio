#!/bin/bash

# Cleanup script for Lab 9: Incident Response and Recovery
# This script removes all resources created for the lab

set -e

# Configuration
ENVIRONMENT="Lab9"
REGION=$(aws configure get region)
STACK_PREFIX="$ENVIRONMENT"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
FORENSICS_BUCKET="$ENVIRONMENT-forensics-$ACCOUNT_ID"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to wait for stack deletion
wait_for_stack_deletion() {
    local stack_name=$1
    echo -e "${YELLOW}Waiting for stack $stack_name to be deleted...${NC}"
    
    aws cloudformation wait stack-delete-complete \
        --stack-name "$stack_name" \
        --region "$REGION"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Stack $stack_name deleted successfully${NC}"
    else
        echo -e "${RED}Stack $stack_name deletion failed${NC}"
        exit 1
    fi
}

# Function to delete a CloudFormation stack
delete_stack() {
    local stack_name=$1
    
    # Check if stack exists
    if aws cloudformation describe-stacks --stack-name "$stack_name" --region "$REGION" >/dev/null 2>&1; then
        echo -e "${YELLOW}Deleting stack: $stack_name${NC}"
        
        aws cloudformation delete-stack \
            --stack-name "$stack_name" \
            --region "$REGION"
        
        wait_for_stack_deletion "$stack_name"
    else
        echo -e "${YELLOW}Stack $stack_name does not exist, skipping...${NC}"
    fi
}

# Function to empty and delete an S3 bucket
delete_bucket() {
    local bucket_name=$1
    
    if aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
        echo "Emptying bucket: $bucket_name"
        aws s3 rm "s3://$bucket_name" --recursive
        
        echo "Deleting bucket: $bucket_name"
        aws s3api delete-bucket --bucket "$bucket_name"
    else
        echo "Bucket $bucket_name does not exist, skipping..."
    fi
}

# Function to delete CloudWatch log groups
delete_log_groups() {
    echo -e "${YELLOW}Deleting CloudWatch log groups...${NC}"
    
    # List and delete all log groups with the environment prefix
    log_groups=$(aws logs describe-log-groups \
        --log-group-name-prefix "/aws/${ENVIRONMENT}" \
        --query 'logGroups[*].logGroupName' \
        --output text)
    
    if [ -n "$log_groups" ]; then
        for log_group in $log_groups; do
            echo "Deleting log group: $log_group"
            aws logs delete-log-group --log-group-name "$log_group"
        done
    fi
}

# Function to delete Lambda functions
delete_lambda_functions() {
    echo -e "${YELLOW}Deleting Lambda functions...${NC}"
    
    # List and delete all Lambda functions with the environment prefix
    functions=$(aws lambda list-functions \
        --query "Functions[?starts_with(FunctionName, '${ENVIRONMENT}')].FunctionName" \
        --output text)
    
    if [ -n "$functions" ]; then
        for function in $functions; do
            echo "Deleting function: $function"
            aws lambda delete-function --function-name "$function"
        done
    fi
}

# Function to delete Step Functions state machines
delete_state_machines() {
    echo -e "${YELLOW}Deleting Step Functions state machines...${NC}"
    
    # List and delete all state machines with the environment prefix
    state_machines=$(aws stepfunctions list-state-machines \
        --query "stateMachines[?starts_with(name, '${ENVIRONMENT}')].stateMachineArn" \
        --output text)
    
    if [ -n "$state_machines" ]; then
        for state_machine in $state_machines; do
            echo "Deleting state machine: $state_machine"
            aws stepfunctions delete-state-machine --state-machine-arn "$state_machine"
        done
    fi
}

# Function to delete SNS topics
delete_sns_topics() {
    echo -e "${YELLOW}Deleting SNS topics...${NC}"
    
    # List and delete all SNS topics with the environment prefix
    topics=$(aws sns list-topics \
        --query "Topics[?contains(TopicArn, '${ENVIRONMENT}')].TopicArn" \
        --output text)
    
    if [ -n "$topics" ]; then
        for topic in $topics; do
            echo "Deleting topic: $topic"
            aws sns delete-topic --topic-arn "$topic"
        done
    fi
}

# Function to delete IAM roles
delete_iam_roles() {
    echo -e "${YELLOW}Deleting IAM roles...${NC}"
    
    # List and delete all IAM roles with the environment prefix
    roles=$(aws iam list-roles \
        --query "Roles[?starts_with(RoleName, '${ENVIRONMENT}')].RoleName" \
        --output text)
    
    if [ -n "$roles" ]; then
        for role in $roles; do
            echo "Deleting attached policies for role: $role"
            
            # Delete inline policies
            policies=$(aws iam list-role-policies --role-name "$role" --query 'PolicyNames' --output text)
            for policy in $policies; do
                aws iam delete-role-policy --role-name "$role" --policy-name "$policy"
            done
            
            # Detach managed policies
            attached_policies=$(aws iam list-attached-role-policies --role-name "$role" --query 'AttachedPolicies[*].PolicyArn' --output text)
            for policy_arn in $attached_policies; do
                aws iam detach-role-policy --role-name "$role" --policy-arn "$policy_arn"
            done
            
            echo "Deleting role: $role"
            aws iam delete-role --role-name "$role"
        done
    fi
}

# Main cleanup process
main() {
    echo -e "${GREEN}Starting cleanup of Lab 9 resources...${NC}"
    
    # Delete CloudFormation stacks in reverse order
    echo -e "${YELLOW}Deleting CloudFormation stacks...${NC}"
    
    # Delete forensics stack first
    delete_stack "${STACK_PREFIX}-forensics"
    
    # Delete incident response stack
    delete_stack "${STACK_PREFIX}-incident-response"
    
    # Clean up other resources
    delete_bucket "$FORENSICS_BUCKET"
    delete_log_groups
    delete_lambda_functions
    delete_state_machines
    delete_sns_topics
    delete_iam_roles
    
    echo -e "${GREEN}Cleanup completed successfully!${NC}"
    
    # Final verification
    echo -e "\n${YELLOW}Verifying cleanup...${NC}"
    
    # Check for remaining stacks
    remaining_stacks=$(aws cloudformation list-stacks \
        --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
        --query "StackSummaries[?contains(StackName, '$ENVIRONMENT')].StackName" \
        --output text)
    
    if [ -n "$remaining_stacks" ]; then
        echo -e "${RED}Warning: Some stacks still exist:${NC}"
        echo "$remaining_stacks"
    else
        echo -e "${GREEN}All stacks have been removed${NC}"
    fi
    
    # Check for remaining Lambda functions
    remaining_functions=$(aws lambda list-functions \
        --query "Functions[?starts_with(FunctionName, '${ENVIRONMENT}')].FunctionName" \
        --output text)
    
    if [ -n "$remaining_functions" ]; then
        echo -e "${RED}Warning: Some Lambda functions still exist:${NC}"
        echo "$remaining_functions"
    else
        echo -e "${GREEN}All Lambda functions have been removed${NC}"
    fi
    
    # Check for remaining SNS topics
    remaining_topics=$(aws sns list-topics \
        --query "Topics[?contains(TopicArn, '${ENVIRONMENT}')].TopicArn" \
        --output text)
    
    if [ -n "$remaining_topics" ]; then
        echo -e "${RED}Warning: Some SNS topics still exist:${NC}"
        echo "$remaining_topics"
    else
        echo -e "${GREEN}All SNS topics have been removed${NC}"
    fi
}

# Execute main function
main "$@" 