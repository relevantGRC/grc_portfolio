#!/bin/bash
# iam-user-lifecycle.sh - IAM User Lifecycle Management Script
# Part of GRC Portfolio Lab 2: Identity and Access Management

# This script provides functions to manage the IAM user lifecycle:
# - Creating new users with proper permissions
# - Auditing existing users for policy compliance
# - Deactivating users (removing access keys and console access)
# - Generating reports on user activity and permissions

# Default settings
DEFAULT_PASSWORD_LENGTH=16
MFA_REQUIRED=true
DEFAULT_PERMISSION_BOUNDARY="arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
DEFAULT_GROUP="StandardUsers"

# Help function
show_help() {
  echo "IAM User Lifecycle Management Script"
  echo "Usage: $0 [command] [options]"
  echo
  echo "Commands:"
  echo "  create-user <username> [--group=<group>] [--permission-boundary=<policy-arn>] [--generate-credentials]"
  echo "  audit-users [--mfa-check] [--password-age=<days>] [--access-key-age=<days>] [--inactive-days=<days>]"
  echo "  deactivate-user <username> [--permanent] [--backup-access-keys]"
  echo "  list-users [--format=csv|json] [--output=<filename>]"
  echo "  rotate-keys <username> [--backup]"
  echo
  echo "Examples:"
  echo "  $0 create-user john-doe --group=Developers --generate-credentials"
  echo "  $0 audit-users --mfa-check --access-key-age=90"
  echo "  $0 deactivate-user jane-smith"
  echo "  $0 list-users --format=csv --output=iam-users.csv"
  echo
}

# Check if AWS CLI is installed and configured
check_aws_cli() {
  if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
  fi

  if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
  fi
}

# Function to create a new IAM user
create_user() {
  local username=$1
  local group=${2:-$DEFAULT_GROUP}
  local permission_boundary=${3:-$DEFAULT_PERMISSION_BOUNDARY}
  local generate_credentials=${4:-false}
  
  echo "Creating IAM user: $username"
  
  # Create the user
  if aws iam create-user --user-name "$username" &> /dev/null; then
    echo "✅ User created successfully"
    
    # Set permission boundary if specified
    if [[ "$permission_boundary" != "none" ]]; then
      aws iam put-user-permissions-boundary --user-name "$username" --permissions-boundary "$permission_boundary"
      echo "✅ Permission boundary set: $permission_boundary"
    fi
    
    # Add user to group if specified
    if [[ "$group" != "none" ]]; then
      # Check if group exists, create if it doesn't
      if ! aws iam get-group --group-name "$group" &> /dev/null; then
        echo "Group $group does not exist. Creating..."
        aws iam create-group --group-name "$group"
        
        # Attach basic permissions to new group
        aws iam attach-group-policy --group-name "$group" --policy-arn "arn:aws:iam::aws:policy/ReadOnlyAccess"
        echo "✅ Created group $group with ReadOnlyAccess"
      fi
      
      aws iam add-user-to-group --user-name "$username" --group-name "$group"
      echo "✅ User added to group: $group"
    fi
    
    # Generate console credentials if requested
    if [[ "$generate_credentials" == "true" ]]; then
      local password=$(openssl rand -base64 $DEFAULT_PASSWORD_LENGTH | tr -d '/+=' | cut -c1-$DEFAULT_PASSWORD_LENGTH)
      
      # Create login profile with a generated password
      aws iam create-login-profile --user-name "$username" --password "$password" --password-reset-required
      
      echo "✅ Console access enabled"
      echo "Initial password: $password"
      echo "User must change password at next login"
      
      # Create access key if requested
      local create_key
      read -p "Create access key for this user? (y/n): " create_key
      if [[ "$create_key" == "y" ]]; then
        local key_output=$(aws iam create-access-key --user-name "$username")
        local access_key_id=$(echo $key_output | jq -r '.AccessKey.AccessKeyId')
        local secret_key=$(echo $key_output | jq -r '.AccessKey.SecretAccessKey')
        
        echo "✅ Access key created"
        echo "Access Key ID: $access_key_id"
        echo "Secret Access Key: $secret_key"
        echo
        echo "⚠️  IMPORTANT: Save these credentials now. The secret key will not be shown again."
        
        # Save credentials to a file
        local credential_file="${username}-credentials.txt"
        echo "IAM User Credentials for $username" > "$credential_file"
        echo "Generated on: $(date)" >> "$credential_file"
        echo "AWS Console:" >> "$credential_file"
        echo "  Username: $username" >> "$credential_file"
        echo "  Password: $password (temporary - must change at first login)" >> "$credential_file"
        echo "AWS API:" >> "$credential_file"
        echo "  Access Key ID: $access_key_id" >> "$credential_file"
        echo "  Secret Access Key: $secret_key" >> "$credential_file"
        
        echo "Credentials saved to $credential_file"
        echo "⚠️  IMPORTANT: Store this file securely and then delete it once credentials are stored in a password manager."
      fi
    fi
    
    if [[ "$MFA_REQUIRED" == "true" ]]; then
      echo
      echo "⚠️  MFA REQUIRED: Remind the user to set up multi-factor authentication immediately."
      echo "    They can do this by going to IAM > Users > $username > Security credentials > Multi-factor authentication (MFA)"
    fi
    
  else
    echo "❌ Failed to create user $username"
  fi
}

# Function to audit IAM users
audit_users() {
  local mfa_check=${1:-true}
  local password_age=${2:-90}
  local access_key_age=${3:-90}
  local inactive_days=${4:-90}
  
  echo "Auditing IAM users..."
  echo "Parameters:"
  echo "  MFA Check: $mfa_check"
  echo "  Password Age: $password_age days"
  echo "  Access Key Age: $access_key_age days"
  echo "  Inactivity Check: $inactive_days days"
  echo
  
  # Generate credential report
  echo "Generating IAM credential report..."
  aws iam generate-credential-report &> /dev/null
  
  # Wait for the report to be generated
  while true; do
    status=$(aws iam get-credential-report --query 'ReportFormat' --output text 2>/dev/null)
    if [[ "$status" == "text/csv" ]]; then
      break
    fi
    echo "Waiting for credential report to be generated..."
    sleep 2
  done
  
  # Get the credential report
  credential_report=$(aws iam get-credential-report --query 'Content' --output text | base64 -d)
  
  # Get the current date in seconds since epoch
  current_date=$(date +%s)
  
  # Process the report
  echo
  echo "=== IAM User Audit Report ==="
  echo "Generated on: $(date)"
  echo
  
  # Initialize counters
  total_users=0
  users_without_mfa=0
  users_with_old_passwords=0
  users_with_old_access_keys=0
  inactive_users=0
  
  # Skip the header row and process each line
  echo "$credential_report" | tail -n +2 | while IFS=',' read -r user arn user_creation_time password_enabled password_last_used password_last_changed password_next_rotation mfa_active access_key_1_active access_key_1_last_rotated access_key_1_last_used_date access_key_2_active access_key_2_last_rotated access_key_2_last_used_date cert_active; do
    
    # Skip the root account
    if [[ "$user" == "<root_account>" ]]; then
      continue
    fi
    
    ((total_users++))
    
    # Check for MFA
    if [[ "$mfa_check" == "true" && "$password_enabled" == "true" && "$mfa_active" == "false" ]]; then
      echo "⚠️  User without MFA: $user"
      ((users_without_mfa++))
    fi
    
    # Check password age
    if [[ "$password_enabled" == "true" && "$password_last_changed" != "N/A" && "$password_last_changed" != "no_information" ]]; then
      password_timestamp=$(date -d "$password_last_changed" +%s)
      password_age_days=$(( (current_date - password_timestamp) / 86400 ))
      
      if [[ $password_age_days -gt $password_age ]]; then
        echo "⚠️  User with old password ($password_age_days days): $user"
        ((users_with_old_passwords++))
      fi
    fi
    
    # Check access key age
    if [[ "$access_key_1_active" == "true" && "$access_key_1_last_rotated" != "N/A" ]]; then
      key1_timestamp=$(date -d "$access_key_1_last_rotated" +%s)
      key1_age_days=$(( (current_date - key1_timestamp) / 86400 ))
      
      if [[ $key1_age_days -gt $access_key_age ]]; then
        echo "⚠️  User with old access key 1 ($key1_age_days days): $user"
        ((users_with_old_access_keys++))
      fi
    fi
    
    if [[ "$access_key_2_active" == "true" && "$access_key_2_last_rotated" != "N/A" ]]; then
      key2_timestamp=$(date -d "$access_key_2_last_rotated" +%s)
      key2_age_days=$(( (current_date - key2_timestamp) / 86400 ))
      
      if [[ $key2_age_days -gt $access_key_age ]]; then
        echo "⚠️  User with old access key 2 ($key2_age_days days): $user"
        ((users_with_old_access_keys++))
      fi
    fi
    
    # Check for inactive users
    local last_activity=""
    local activity_timestamp=0
    
    # Find the most recent activity between password and access keys
    if [[ "$password_last_used" != "N/A" && "$password_last_used" != "no_information" && "$password_last_used" != "2014-10-16T16:30:03+00:00" ]]; then
      last_activity="$password_last_used"
      activity_timestamp=$(date -d "$password_last_used" +%s)
    fi
    
    if [[ "$access_key_1_last_used_date" != "N/A" && "$access_key_1_last_used_date" != "no_information" ]]; then
      key1_timestamp=$(date -d "$access_key_1_last_used_date" +%s)
      if [[ $key1_timestamp -gt $activity_timestamp ]]; then
        last_activity="$access_key_1_last_used_date"
        activity_timestamp=$key1_timestamp
      fi
    fi
    
    if [[ "$access_key_2_last_used_date" != "N/A" && "$access_key_2_last_used_date" != "no_information" ]]; then
      key2_timestamp=$(date -d "$access_key_2_last_used_date" +%s)
      if [[ $key2_timestamp -gt $activity_timestamp ]]; then
        last_activity="$access_key_2_last_used_date"
        activity_timestamp=$key2_timestamp
      fi
    fi
    
    # If we have activity data, check for inactivity
    if [[ $activity_timestamp -gt 0 ]]; then
      inactive_days_count=$(( (current_date - activity_timestamp) / 86400 ))
      
      if [[ $inactive_days_count -gt $inactive_days ]]; then
        echo "⚠️  Inactive user ($inactive_days_count days): $user"
        ((inactive_users++))
      fi
    fi
  done
  
  # Summary
  echo
  echo "=== Summary ==="
  echo "Total Users: $total_users"
  echo "Users Without MFA: $users_without_mfa"
  echo "Users With Old Passwords: $users_with_old_passwords"
  echo "Users With Old Access Keys: $users_with_old_access_keys"
  echo "Inactive Users: $inactive_users"
  echo
  
  # Generate a report date
  report_date=$(date +"%Y-%m-%d")
  report_file="iam-audit-report-$report_date.txt"
  
  # Save the report to a file
  {
    echo "IAM User Audit Report"
    echo "Generated on: $(date)"
    echo
    echo "Parameters:"
    echo "  MFA Check: $mfa_check"
    echo "  Password Age: $password_age days"
    echo "  Access Key Age: $access_key_age days"
    echo "  Inactivity Check: $inactive_days days"
    echo
    echo "=== Summary ==="
    echo "Total Users: $total_users"
    echo "Users Without MFA: $users_without_mfa"
    echo "Users With Old Passwords: $users_with_old_passwords"
    echo "Users With Old Access Keys: $users_with_old_access_keys"
    echo "Inactive Users: $inactive_users"
    echo
    echo "=== Detailed Findings ==="
    # Add detailed findings here from the previous analysis
  } > "$report_file"
  
  echo "Report saved to: $report_file"
}

# Function to deactivate an IAM user
deactivate_user() {
  local username=$1
  local permanent=${2:-false}
  local backup_keys=${3:-true}
  
  echo "Deactivating IAM user: $username"
  
  # Check if user exists
  if ! aws iam get-user --user-name "$username" &> /dev/null; then
    echo "❌ User $username does not exist"
    return 1
  fi
  
  echo "⚠️  This will remove all access for $username!"
  if [[ "$permanent" == "true" ]]; then
    echo "⚠️  PERMANENT DELETION REQUESTED! This will completely remove the user account."
  fi
  
  local confirm
  read -p "Are you sure you want to proceed? (y/n): " confirm
  if [[ "$confirm" != "y" ]]; then
    echo "Operation cancelled"
    return 0
  fi
  
  # Backup access keys if requested
  if [[ "$backup_keys" == "true" ]]; then
    local keys_file="${username}-access-keys-backup.txt"
    echo "Access Keys Backup for $username" > "$keys_file"
    echo "Generated on: $(date)" >> "$keys_file"
    
    # Get access key 1
    if aws iam list-access-keys --user-name "$username" --query "AccessKeyMetadata[?AccessKeyId].AccessKeyId" --output text | grep -q ".*"; then
      local key_ids=$(aws iam list-access-keys --user-name "$username" --query "AccessKeyMetadata[].AccessKeyId" --output text)
      echo "Access Key IDs:" >> "$keys_file"
      echo "$key_ids" >> "$keys_file"
      echo "✅ Access keys backed up to $keys_file"
      echo "Note: Secret keys cannot be retrieved and must be regenerated if needed."
    else
      echo "No access keys found for $username"
    fi
  fi
  
  # Delete access keys
  for key_id in $(aws iam list-access-keys --user-name "$username" --query "AccessKeyMetadata[].AccessKeyId" --output text); do
    aws iam delete-access-key --user-name "$username" --access-key-id "$key_id"
    echo "✅ Deleted access key: $key_id"
  done
  
  # Deactivate console access
  if aws iam get-login-profile --user-name "$username" &> /dev/null; then
    aws iam delete-login-profile --user-name "$username"
    echo "✅ Removed console access"
  fi
  
  # Remove MFA devices
  for mfa_device in $(aws iam list-mfa-devices --user-name "$username" --query "MFADevices[].SerialNumber" --output text); do
    aws iam deactivate-mfa-device --user-name "$username" --serial-number "$mfa_device"
    echo "✅ Deactivated MFA device: $mfa_device"
  done
  
  # Remove user from groups
  for group in $(aws iam list-groups-for-user --user-name "$username" --query "Groups[].GroupName" --output text); do
    aws iam remove-user-from-group --user-name "$username" --group-name "$group"
    echo "✅ Removed from group: $group"
  done
  
  # Detach all policies
  for policy in $(aws iam list-attached-user-policies --user-name "$username" --query "AttachedPolicies[].PolicyArn" --output text); do
    aws iam detach-user-policy --user-name "$username" --policy-arn "$policy"
    echo "✅ Detached policy: $policy"
  done
  
  # Delete inline policies
  for policy in $(aws iam list-user-policies --user-name "$username" --query "PolicyNames[]" --output text); do
    aws iam delete-user-policy --user-name "$username" --policy-name "$policy"
    echo "✅ Deleted inline policy: $policy"
  done
  
  # Permanently delete the user if requested
  if [[ "$permanent" == "true" ]]; then
    aws iam delete-user --user-name "$username"
    echo "✅ User $username has been permanently deleted"
  else
    # Add a tag to indicate the user is deactivated
    aws iam tag-user --user-name "$username" --tags "Key=Status,Value=Deactivated" "Key=DeactivationDate,Value=$(date +%Y-%m-%d)"
    echo "✅ User $username has been deactivated but not deleted"
    echo "   Tagged as deactivated on $(date +%Y-%m-%d)"
  fi
  
  echo "Deactivation of $username completed successfully"
}

# Function to list all IAM users
list_users() {
  local format=${1:-"table"}
  local output_file=${2:-""}
  
  echo "Listing IAM users..."
  
  # Get list of users
  local users=$(aws iam list-users --query "Users[].[UserName,CreateDate,PasswordLastUsed]" --output json)
  
  # Process the results
  case "$format" in
    csv)
      # CSV header
      echo "Username,Created,PasswordLastUsed,MFA,AccessKey1,AccessKey1Active,AccessKey2,AccessKey2Active" > "${output_file:-/dev/stdout}"
      
      # Process each user
      echo "$users" | jq -r '.[] | @sh' | while read -r line; do
        # Extract user info
        eval user=($line)
        username="${user[0]//\"/}"
        created="${user[1]//\"/}"
        password_last_used="${user[2]//\"/}"
        
        # Handle null/empty values
        if [[ "$password_last_used" == "null" ]]; then
          password_last_used="Never"
        fi
        
        # Get MFA status
        mfa_devices=$(aws iam list-mfa-devices --user-name "$username" --query "length(MFADevices)" --output text)
        mfa_status="No"
        if [[ "$mfa_devices" -gt 0 ]]; then
          mfa_status="Yes"
        fi
        
        # Get access key info
        access_keys=$(aws iam list-access-keys --user-name "$username" --query "AccessKeyMetadata[].[AccessKeyId,Status]" --output text)
        
        # Default values
        access_key1=""
        access_key1_active="No"
        access_key2=""
        access_key2_active="No"
        
        # Process access keys
        i=1
        echo "$access_keys" | while read -r key_id key_status; do
          if [[ $i -eq 1 ]]; then
            access_key1="$key_id"
            if [[ "$key_status" == "Active" ]]; then
              access_key1_active="Yes"
            fi
          elif [[ $i -eq 2 ]]; then
            access_key2="$key_id"
            if [[ "$key_status" == "Active" ]]; then
              access_key2_active="Yes"
            fi
          fi
          ((i++))
        done
        
        # Output CSV line
        echo "$username,$created,$password_last_used,$mfa_status,$access_key1,$access_key1_active,$access_key2,$access_key2_active" >> "${output_file:-/dev/stdout}"
      done
      ;;
      
    json)
      # Process users and add additional info
      echo "$users" | jq -r '.[] | .[0]' | while read -r username; do
        # Get MFA status
        mfa_devices=$(aws iam list-mfa-devices --user-name "$username" --query "length(MFADevices)" --output text)
        mfa_enabled=false
        if [[ "$mfa_devices" -gt 0 ]]; then
          mfa_enabled=true
        fi
        
        # Get access key info
        access_keys=$(aws iam list-access-keys --user-name "$username" --query "AccessKeyMetadata[].[AccessKeyId,Status,CreateDate]" --output json)
        
        # Get group membership
        groups=$(aws iam list-groups-for-user --user-name "$username" --query "Groups[].GroupName" --output json)
        
        # Get attached policies
        policies=$(aws iam list-attached-user-policies --user-name "$username" --query "AttachedPolicies[].PolicyName" --output json)
        
        # Build user object
        user_info=$(jq -n \
          --arg username "$username" \
          --argjson mfa_enabled "$mfa_enabled" \
          --argjson access_keys "$access_keys" \
          --argjson groups "$groups" \
          --argjson policies "$policies" \
          '{username: $username, mfa_enabled: $mfa_enabled, access_keys: $access_keys, groups: $groups, policies: $policies}')
        
        echo "$user_info" >> "${output_file:-/dev/stdout}"
      done
      ;;
      
    *)
      # Default table format
      printf "%-20s %-20s %-25s %-6s %-20s\n" "Username" "Created" "Password Last Used" "MFA" "Access Keys"
      printf "%-20s %-20s %-25s %-6s %-20s\n" "--------------------" "--------------------" "-------------------------" "------" "--------------------"
      
      echo "$users" | jq -r '.[] | @sh' | while read -r line; do
        # Extract user info
        eval user=($line)
        username="${user[0]//\"/}"
        created=$(date -d "${user[1]//\"/}" "+%Y-%m-%d")
        password_last_used="${user[2]//\"/}"
        
        # Handle null/empty values
        if [[ "$password_last_used" == "null" ]]; then
          password_last_used="Never"
        else
          password_last_used=$(date -d "$password_last_used" "+%Y-%m-%d")
        fi
        
        # Get MFA status
        mfa_devices=$(aws iam list-mfa-devices --user-name "$username" --query "length(MFADevices)" --output text)
        mfa_status="No"
        if [[ "$mfa_devices" -gt 0 ]]; then
          mfa_status="Yes"
        fi
        
        # Get access key info
        access_key_count=$(aws iam list-access-keys --user-name "$username" --query "length(AccessKeyMetadata)" --output text)
        
        # Output table row
        printf "%-20s %-20s %-25s %-6s %-20s\n" "$username" "$created" "$password_last_used" "$mfa_status" "$access_key_count active"
      done
      ;;
  esac
}

# Function to rotate access keys
rotate_keys() {
  local username=$1
  local backup=${2:-true}
  
  echo "Rotating access keys for IAM user: $username"
  
  # Check if user exists
  if ! aws iam get-user --user-name "$username" &> /dev/null; then
    echo "❌ User $username does not exist"
    return 1
  fi
  
  # Get current access keys
  local current_keys=$(aws iam list-access-keys --user-name "$username" --query "AccessKeyMetadata[?Status=='Active'].[AccessKeyId]" --output text)
  local key_count=$(echo "$current_keys" | wc -w)
  
  if [[ $key_count -eq 0 ]]; then
    # No active keys, create a new one
    echo "No active access keys found. Creating new access key..."
    local key_output=$(aws iam create-access-key --user-name "$username")
    local new_key_id=$(echo $key_output | jq -r '.AccessKey.AccessKeyId')
    local new_secret=$(echo $key_output | jq -r '.AccessKey.SecretAccessKey')
    
    echo "✅ Created new access key: $new_key_id"
    echo "Secret Access Key: $new_secret"
    
    # Save new key to file
    if [[ "$backup" == "true" ]]; then
      local key_file="${username}-new-access-key.txt"
      echo "New Access Key for $username" > "$key_file"
      echo "Generated on: $(date)" >> "$key_file"
      echo "Access Key ID: $new_key_id" >> "$key_file"
      echo "Secret Access Key: $new_secret" >> "$key_file"
      echo "✅ New access key saved to $key_file"
    fi
    
  elif [[ $key_count -ge 2 ]]; then
    # Already have 2 keys, need to delete one first
    echo "⚠️  User already has $key_count active access keys. Maximum is 2."
    echo "Please specify which key to delete first:"
    
    local i=1
    for key_id in $current_keys; do
      local key_created=$(aws iam list-access-keys --user-name "$username" --query "AccessKeyMetadata[?AccessKeyId=='$key_id'].CreateDate" --output text)
      echo "$i) $key_id (created: $key_created)"
      ((i++))
    done
    
    local key_to_delete
    read -p "Enter key number to delete (1-$key_count): " key_to_delete
    
    if [[ $key_to_delete -ge 1 && $key_to_delete -le $key_count ]]; then
      local selected_key=$(echo "$current_keys" | awk -v line=$key_to_delete 'NR==line {print}')
      
      echo "Deleting access key: $selected_key"
      aws iam delete-access-key --user-name "$username" --access-key-id "$selected_key"
      echo "✅ Deleted access key: $selected_key"
      
      # Now create a new key
      echo "Creating new access key..."
      local key_output=$(aws iam create-access-key --user-name "$username")
      local new_key_id=$(echo $key_output | jq -r '.AccessKey.AccessKeyId')
      local new_secret=$(echo $key_output | jq -r '.AccessKey.SecretAccessKey')
      
      echo "✅ Created new access key: $new_key_id"
      echo "Secret Access Key: $new_secret"
      
      # Save new key to file
      if [[ "$backup" == "true" ]]; then
        local key_file="${username}-new-access-key.txt"
        echo "New Access Key for $username" > "$key_file"
        echo "Generated on: $(date)" >> "$key_file"
        echo "Access Key ID: $new_key_id" >> "$key_file"
        echo "Secret Access Key: $new_secret" >> "$key_file"
        echo "✅ New access key saved to $key_file"
      fi
      
    else
      echo "❌ Invalid selection"
      return 1
    fi
    
  else
    # Have one key, create a second one before deleting the first
    echo "Creating a new access key before deactivating the old one..."
    local key_output=$(aws iam create-access-key --user-name "$username")
    local new_key_id=$(echo $key_output | jq -r '.AccessKey.AccessKeyId')
    local new_secret=$(echo $key_output | jq -r '.AccessKey.SecretAccessKey')
    
    echo "✅ Created new access key: $new_key_id"
    echo "Secret Access Key: $new_secret"
    
    # Save new key to file
    if [[ "$backup" == "true" ]]; then
      local key_file="${username}-new-access-key.txt"
      echo "New Access Key for $username" > "$key_file"
      echo "Generated on: $(date)" >> "$key_file"
      echo "Access Key ID: $new_key_id" >> "$key_file"
      echo "Secret Access Key: $new_secret" >> "$key_file"
      echo "✅ New access key saved to $key_file"
    fi
    
    echo
    echo "The next step is to update your applications with the new key."
    echo "After confirming the new key works, you should delete the old key."
    
    local old_key_id=$(echo "$current_keys")
    local delete_old
    read -p "Delete the old access key now? ($old_key_id) (y/n): " delete_old
    
    if [[ "$delete_old" == "y" ]]; then
      aws iam delete-access-key --user-name "$username" --access-key-id "$old_key_id"
      echo "✅ Deleted old access key: $old_key_id"
    else
      echo "Old access key was not deleted. You can delete it manually when ready."
    fi
  fi
  
  echo "Access key rotation completed for $username"
}

# Main script logic
main() {
  # Show help if no arguments provided
  if [[ $# -eq 0 ]]; then
    show_help
    exit 0
  fi
  
  # Check AWS CLI
  check_aws_cli
  
  # Parse command
  local command=$1
  shift
  
  case "$command" in
    create-user)
      if [[ $# -lt 1 ]]; then
        echo "Error: Username required"
        show_help
        exit 1
      fi
      
      local username=$1
      shift
      
      local group="$DEFAULT_GROUP"
      local permission_boundary="$DEFAULT_PERMISSION_BOUNDARY"
      local generate_credentials=false
      
      # Parse options
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --group=*)
            group="${1#*=}"
            shift
            ;;
          --permission-boundary=*)
            permission_boundary="${1#*=}"
            shift
            ;;
          --generate-credentials)
            generate_credentials=true
            shift
            ;;
          *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
        esac
      done
      
      create_user "$username" "$group" "$permission_boundary" "$generate_credentials"
      ;;
      
    audit-users)
      local mfa_check=true
      local password_age=90
      local access_key_age=90
      local inactive_days=90
      
      # Parse options
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --mfa-check=*)
            mfa_check="${1#*=}"
            shift
            ;;
          --password-age=*)
            password_age="${1#*=}"
            shift
            ;;
          --access-key-age=*)
            access_key_age="${1#*=}"
            shift
            ;;
          --inactive-days=*)
            inactive_days="${1#*=}"
            shift
            ;;
          *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
        esac
      done
      
      audit_users "$mfa_check" "$password_age" "$access_key_age" "$inactive_days"
      ;;
      
    deactivate-user)
      if [[ $# -lt 1 ]]; then
        echo "Error: Username required"
        show_help
        exit 1
      fi
      
      local username=$1
      shift
      
      local permanent=false
      local backup_keys=true
      
      # Parse options
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --permanent)
            permanent=true
            shift
            ;;
          --backup-access-keys=*)
            backup_keys="${1#*=}"
            shift
            ;;
          *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
        esac
      done
      
      deactivate_user "$username" "$permanent" "$backup_keys"
      ;;
      
    list-users)
      local format="table"
      local output_file=""
      
      # Parse options
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --format=*)
            format="${1#*=}"
            shift
            ;;
          --output=*)
            output_file="${1#*=}"
            shift
            ;;
          *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
        esac
      done
      
      list_users "$format" "$output_file"
      ;;
      
    rotate-keys)
      if [[ $# -lt 1 ]]; then
        echo "Error: Username required"
        show_help
        exit 1
      fi
      
      local username=$1
      shift
      
      local backup=true
      
      # Parse options
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --backup=*)
            backup="${1#*=}"
            shift
            ;;
          *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
        esac
      done
      
      rotate_keys "$username" "$backup"
      ;;
      
    help|--help|-h)
      show_help
      ;;
      
    *)
      echo "Unknown command: $command"
      show_help
      exit 1
      ;;
  esac
}

# Run the script
main "$@" 