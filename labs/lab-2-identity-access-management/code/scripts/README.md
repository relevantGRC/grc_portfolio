# Support Scripts for Lab 2: Identity and Access Management

This directory contains helpful scripts to assist with implementing, managing, and auditing IAM users, roles, and permissions in your AWS account.

## Available Scripts

### 1. iam-user-lifecycle.sh

A comprehensive script for managing the entire lifecycle of IAM users, from creation to deactivation.

**Usage**:
```bash
# Show help and available commands
./iam-user-lifecycle.sh

# Create a new user with default settings
./iam-user-lifecycle.sh create-user john-doe

# Create a user with specific group and generated credentials
./iam-user-lifecycle.sh create-user jane-smith --group=Developers --generate-credentials

# Audit users for policy compliance
./iam-user-lifecycle.sh audit-users --mfa-check=true --access-key-age=90

# List all IAM users in CSV format
./iam-user-lifecycle.sh list-users --format=csv --output=users.csv

# Rotate access keys for a user
./iam-user-lifecycle.sh rotate-keys john-doe

# Deactivate a user (remove all access)
./iam-user-lifecycle.sh deactivate-user jane-smith
```

**Features**:
- User creation with permission boundaries and group assignment
- Secure credential generation and management
- MFA enforcement and verification
- Comprehensive user auditing (password age, access key age, MFA status)
- User deactivation with proper cleanup
- Access key rotation with backup
- Detailed reporting in multiple formats

**Requirements**:
- AWS CLI installed and configured
- Bash shell environment
- `jq` command-line JSON processor
- Appropriate IAM permissions to manage users

## Adding Your Own Scripts

Feel free to create additional scripts to enhance your IAM management capabilities. Some ideas:

- **iam-roles-report.sh**: Generate a detailed report of all IAM roles and their trusted entities
- **permission-analyzer.sh**: Analyze effective permissions for a user or role
- **cross-account-access-setup.sh**: Automate creation of cross-account access roles
- **federation-setup.sh**: Setup and configure identity federation with external providers

## Using These Scripts

1. Make the scripts executable:
   ```bash
   chmod +x iam-user-lifecycle.sh
   ```

2. Ensure you have the AWS CLI installed and configured with appropriate credentials:
   ```bash
   aws configure
   ```

3. Install jq if needed:
   ```bash
   # For Debian/Ubuntu
   sudo apt-get install jq
   
   # For Red Hat/CentOS
   sudo yum install jq
   
   # For macOS with Homebrew
   brew install jq
   ```

4. Run the scripts as needed during or after completing the lab

## Security Considerations

- These scripts create and manage IAM users and their credentials
- Always follow the principle of least privilege when creating users and roles
- Securely store any generated credentials and delete credential files after use
- Consider using AWS Secrets Manager for storing sensitive information
- Remember to rotate access keys regularly (90 days is a common best practice)

## Troubleshooting

If you encounter issues with these scripts:

1. Ensure AWS CLI is properly installed and configured
2. Verify that you have sufficient IAM permissions in your AWS account
3. Check for syntax errors if you've modified the scripts
4. For detailed errors, add the `-x` flag to the bash shebang line for verbose output
5. Ensure `jq` is properly installed for JSON parsing

For specific error messages, consult the AWS CLI documentation for IAM services. 