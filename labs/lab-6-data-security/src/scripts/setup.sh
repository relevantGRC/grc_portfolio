#!/bin/bash

# =========================================================================
# Setup Script for Lab 6: Data Security
# =========================================================================
# This script sets up the necessary resources for the Data Security lab.
# It creates sample data files with different classifications and uploads
# them to the S3 bucket with appropriate tags.
# =========================================================================

# Set up colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print script header
echo -e "${BLUE}=== Setting up Data Security Lab Resources ===${NC}"

# Check if bucket name was provided
if [ $# -lt 1 ]; then
    echo -e "${RED}Error: S3 bucket name is required.${NC}"
    echo -e "Usage: $0 <bucket-name>"
    exit 1
fi

BUCKET_NAME=$1

# Check if the bucket exists
echo -e "${YELLOW}Checking if bucket ${BUCKET_NAME} exists...${NC}"
if ! aws s3 ls "s3://${BUCKET_NAME}" > /dev/null 2>&1; then
    echo -e "${RED}Error: Bucket ${BUCKET_NAME} does not exist or you don't have access to it.${NC}"
    exit 1
fi

echo -e "${GREEN}Bucket ${BUCKET_NAME} exists.${NC}"

# Create a temporary directory for sample files
echo -e "${YELLOW}Creating temporary directory for sample files...${NC}"
TEMP_DIR=$(mktemp -d)
echo -e "${GREEN}Temporary directory created at ${TEMP_DIR}${NC}"

# Create data classification definition
echo -e "${YELLOW}Creating data classification definition...${NC}"
cat > "${TEMP_DIR}/classification.json" << EOF
{
  "classifications": [
    {
      "level": "Public",
      "description": "Data that can be freely shared"
    },
    {
      "level": "Internal",
      "description": "Data for internal use only"
    },
    {
      "level": "Sensitive",
      "description": "Data that requires protection"
    },
    {
      "level": "Confidential",
      "description": "Highly sensitive data"
    },
    {
      "level": "Restricted",
      "description": "Most sensitive data with strict access controls"
    }
  ]
}
EOF

# Create sample data files with different classifications
echo -e "${YELLOW}Creating sample data files...${NC}"

# Public data
echo "This is public information that can be freely shared." > "${TEMP_DIR}/public-data.txt"

# Internal data
echo "This is internal information for company use only." > "${TEMP_DIR}/internal-data.txt"

# Sensitive data
cat > "${TEMP_DIR}/sensitive-data.txt" << EOF
This document contains sensitive information including:
- Credit card number: 4111-1111-1111-1111
- Employee ID: EMP12345
- Project code names: FALCON, EAGLE, HAWK
EOF

# Confidential data
cat > "${TEMP_DIR}/confidential-data.txt" << EOF
CONFIDENTIAL: This document contains trade secrets and proprietary information.
- Product roadmap for next 12 months
- Upcoming merger details
- Financial projections for FY2023
EOF

# Restricted data
cat > "${TEMP_DIR}/restricted-data.txt" << EOF
RESTRICTED: This document contains PII and other highly sensitive information.
- SSN: 123-45-6789
- DOB: 01/01/1980
- Home address: 123 Main St, Anytown, USA
- Salary information: $150,000
- Medical information: Patient diagnosed with...
EOF

# Upload files to S3 with appropriate tags
echo -e "${YELLOW}Uploading files to S3 bucket with appropriate tags...${NC}"

# Upload classification definition
echo -e "${YELLOW}Uploading classification definition...${NC}"
aws s3 cp "${TEMP_DIR}/classification.json" "s3://${BUCKET_NAME}/" \
    --metadata "Classification=Public" \
    --tagging "DataClassification=Public"

# Upload public data
echo -e "${YELLOW}Uploading public data...${NC}"
aws s3 cp "${TEMP_DIR}/public-data.txt" "s3://${BUCKET_NAME}/" \
    --metadata "Classification=Public" \
    --tagging "DataClassification=Public"

# Upload internal data
echo -e "${YELLOW}Uploading internal data...${NC}"
aws s3 cp "${TEMP_DIR}/internal-data.txt" "s3://${BUCKET_NAME}/" \
    --metadata "Classification=Internal" \
    --tagging "DataClassification=Internal"

# Upload sensitive data
echo -e "${YELLOW}Uploading sensitive data...${NC}"
aws s3 cp "${TEMP_DIR}/sensitive-data.txt" "s3://${BUCKET_NAME}/" \
    --metadata "Classification=Sensitive" \
    --tagging "DataClassification=Sensitive"

# Upload confidential data
echo -e "${YELLOW}Uploading confidential data...${NC}"
aws s3 cp "${TEMP_DIR}/confidential-data.txt" "s3://${BUCKET_NAME}/" \
    --metadata "Classification=Confidential" \
    --tagging "DataClassification=Confidential"

# Upload restricted data
echo -e "${YELLOW}Uploading restricted data...${NC}"
aws s3 cp "${TEMP_DIR}/restricted-data.txt" "s3://${BUCKET_NAME}/" \
    --metadata "Classification=Restricted" \
    --tagging "DataClassification=Restricted"

# Clean up temporary directory
echo -e "${YELLOW}Cleaning up temporary directory...${NC}"
rm -rf "${TEMP_DIR}"

echo -e "${GREEN}Setup complete! Sample data files have been uploaded to ${BUCKET_NAME}.${NC}"
echo -e "${GREEN}You can now proceed with the lab exercises.${NC}"