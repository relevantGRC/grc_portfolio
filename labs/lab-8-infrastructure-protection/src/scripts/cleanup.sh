#!/bin/bash

# Cleanup script for Lab 8: Infrastructure and Network Protection
# This script removes all resources created for the lab

set -e

# Configuration
ENVIRONMENT="Lab8"
REGION=$(aws configure get region)
STACK_PREFIX="$ENVIRONMENT"

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

# Function to clean up WAF resources
cleanup_waf() {
    echo -e "${YELLOW}Cleaning up WAF resources...${NC}"
    
    # List and delete WAF ACLs
    web_acls=$(aws wafv2 list-web-acls \
        --scope REGIONAL \
        --region "$REGION" \
        --query 'WebACLs[?contains(Name, `'${ENVIRONMENT}'`)].Id' \
        --output text)
    
    if [ -n "$web_acls" ]; then
        for acl_id in $web_acls; do
            echo "Deleting Web ACL: $acl_id"
            aws wafv2 delete-web-acl \
                --id "$acl_id" \
                --name "${ENVIRONMENT}-web-acl" \
                --scope REGIONAL \
                --region "$REGION"
        done
    fi
}

# Function to clean up Shield resources
cleanup_shield() {
    echo -e "${YELLOW}Cleaning up Shield resources...${NC}"
    
    # List and delete Shield protections
    protections=$(aws shield list-protections \
        --query 'Protections[?contains(ResourceArn, `'${ENVIRONMENT}'`)].ProtectionId' \
        --output text)
    
    if [ -n "$protections" ]; then
        for protection_id in $protections; do
            echo "Deleting Shield protection: $protection_id"
            aws shield delete-protection --protection-id "$protection_id"
        done
    fi
}

# Function to clean up GuardDuty
cleanup_guardduty() {
    echo -e "${YELLOW}Cleaning up GuardDuty resources...${NC}"
    
    # Get detector ID
    detector_id=$(aws guardduty list-detectors --query 'DetectorIds[0]' --output text)
    
    if [ -n "$detector_id" ] && [ "$detector_id" != "None" ]; then
        echo "Disabling GuardDuty detector: $detector_id"
        aws guardduty delete-detector --detector-id "$detector_id"
    fi
}

# Function to clean up Security Hub
cleanup_security_hub() {
    echo -e "${YELLOW}Cleaning up Security Hub...${NC}"
    
    # Disable Security Hub
    if aws securityhub get-enabled-standards >/dev/null 2>&1; then
        echo "Disabling Security Hub"
        aws securityhub disable-security-hub
    fi
}

# Main cleanup process
main() {
    echo -e "${GREEN}Starting cleanup of Lab 8 resources...${NC}"
    
    # Delete CloudFormation stacks in reverse order
    echo -e "${YELLOW}Deleting CloudFormation stacks...${NC}"
    
    # Delete monitoring stack first
    delete_stack "${STACK_PREFIX}-monitoring"
    
    # Delete Shield stack
    delete_stack "${STACK_PREFIX}-shield"
    
    # Delete WAF stack
    delete_stack "${STACK_PREFIX}-waf"
    
    # Delete network infrastructure stack last
    delete_stack "${STACK_PREFIX}-network"
    
    # Clean up other resources
    cleanup_waf
    cleanup_shield
    cleanup_guardduty
    cleanup_security_hub
    delete_log_groups
    
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
}

# Execute main function
main "$@" 