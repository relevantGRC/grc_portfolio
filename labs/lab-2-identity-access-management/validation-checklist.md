# Lab 2: Identity and Access Management - Validation Checklist

This checklist helps you verify that you have successfully implemented the identity and access management infrastructure described in the lab guide. Complete each verification step and check off items as you confirm their implementation.

## Module 1: IAM Foundations and Best Practices

### IAM Password Policy

- [ ] **Verify password policy settings**
  ```bash
  aws iam get-account-password-policy
  ```
  - Confirm the following settings:
    - [ ] Minimum password length ≥ 14 characters
    - [ ] Requires at least one uppercase letter
    - [ ] Requires at least one lowercase letter
    - [ ] Requires at least one number
    - [ ] Requires at least one non-alphanumeric character
    - [ ] Password expiration is enabled (≤ 90 days)
    - [ ] Password reuse prevention is enabled (≥ 24 previous passwords)

### IAM Admin User with MFA

- [ ] **Verify the iam-administrator user exists**
  ```bash
  aws iam get-user --user-name iam-administrator
  ```

- [ ] **Verify MFA is enabled for the iam-administrator user**
  ```bash
  aws iam list-mfa-devices --user-name iam-administrator
  ```
  - Confirm that at least one MFA device is listed

- [ ] **Verify iam-administrator has appropriate permissions**
  ```bash
  aws iam list-attached-user-policies --user-name iam-administrator
  ```
  - Confirm the IAMFullAccess policy is attached

### IAM User Lifecycle Management

- [ ] **Verify the iam-user-lifecycle.sh script is executable**
  ```bash
  ls -la code/scripts/iam-user-lifecycle.sh
  ```
  - Confirm the script has execute permissions

- [ ] **Test the iam-user-lifecycle.sh script help command**
  ```bash
  ./code/scripts/iam-user-lifecycle.sh help
  ```
  - Confirm the help text is displayed with available commands

## Module 2: Role-Based Access Control

### IAM Roles

- [ ] **Verify the EC2-S3ReadOnly role exists**
  ```bash
  aws iam get-role --role-name EC2-S3ReadOnly
  ```
  - Confirm the trust relationship allows EC2 to assume the role

- [ ] **Verify the DevOps-Role exists**
  ```bash
  aws iam get-role --role-name DevOps-Role
  ```
  - Confirm appropriate permissions are attached

- [ ] **Verify the Security-Auditor role exists**
  ```bash
  aws iam get-role --role-name Security-Auditor
  ```
  - Confirm it has SecurityAudit and IAMReadOnlyAccess policies

- [ ] **Verify the Finance-Billing role exists**
  ```bash
  aws iam get-role --role-name Finance-Billing
  ```
  - Confirm it has Billing and AWSBudgetsReadOnlyAccess policies

### Custom IAM Policies

- [ ] **Verify the RestrictedS3Access policy exists**
  ```bash
  aws iam get-policy --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/RestrictedS3Access
  ```

- [ ] **Verify the IT-EC2Monitoring policy exists**
  ```bash
  aws iam get-policy --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/IT-EC2Monitoring
  ```

- [ ] **Check the RestrictedS3Access policy content**
  ```bash
  aws iam get-policy-version --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/RestrictedS3Access --version-id $(aws iam get-policy --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/RestrictedS3Access --query Policy.DefaultVersionId --output text)
  ```
  - Confirm it includes condition for IP address restriction

## Module 3: Permission Boundaries and SCPs

### Permission Boundary Policy

- [ ] **Verify the DevOpsPermissionBoundary exists**
  ```bash
  aws iam get-policy --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/DevOpsPermissionBoundary
  ```

- [ ] **Check the permission boundary content**
  ```bash
  aws iam get-policy-version --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/DevOpsPermissionBoundary --version-id $(aws iam get-policy --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/DevOpsPermissionBoundary --query Policy.DefaultVersionId --output text)
  ```
  - Confirm it allows specific services and denies IAM/Organizations actions

- [ ] **Verify the boundary is applied to the DevOps role**
  ```bash
  aws iam get-role --role-name DevOps-Role
  ```
  - Confirm the PermissionsBoundary property is set to the DevOpsPermissionBoundary policy

### Service Control Policies (SCPs)

**Note**: This check applies only if you're using AWS Organizations

- [ ] **Verify the PreventIAMUserCreation SCP exists**
  ```bash
  aws organizations list-policies --filter SERVICE_CONTROL_POLICY
  ```
  - Locate the PreventIAMUserCreation policy in the list

- [ ] **Check that the SCP is attached to an OU**
  ```bash
  aws organizations list-targets-for-policy --policy-id [policy-id]
  ```
  - Replace [policy-id] with the ID from the previous command
  - Confirm it's attached to the appropriate organizational unit

## Module 4: Identity Federation

### IAM Identity Center (AWS SSO)

- [ ] **Verify IAM Identity Center is enabled**
  ```bash
  aws sso-admin list-instances
  ```
  - Confirm at least one instance is listed

- [ ] **Verify users exist in IAM Identity Center**
  ```bash
  aws identitystore list-users --identity-store-id [identity-store-id]
  ```
  - Replace [identity-store-id] with the ID from the instance above
  - Confirm the sso-admin user exists

### SAML Identity Provider (Optional)

- [ ] **Verify the SAML provider exists (if configured)**
  ```bash
  aws iam list-saml-providers
  ```
  - Look for ExternalSAMLProvider in the list

- [ ] **Verify the FederatedReadOnly role exists (if using SAML)**
  ```bash
  aws iam get-role --role-name FederatedReadOnly
  ```
  - Confirm the trust relationship allows federation with the SAML provider

## Module 5: Access Analysis and Monitoring

### IAM Access Analyzer

- [ ] **Verify IAM Access Analyzer is enabled**
  ```bash
  aws accessanalyzer list-analyzers
  ```
  - Confirm the AccountAccessAnalyzer exists with status ACTIVE

### CloudTrail for IAM Activity Monitoring

- [ ] **Verify the IAM-specific CloudTrail trail exists**
  ```bash
  aws cloudtrail describe-trails
  ```
  - Look for IAMActivityTrail in the list

- [ ] **Verify CloudWatch Logs integration**
  ```bash
  aws cloudtrail get-trail-status --name IAMActivityTrail
  ```
  - Confirm CloudWatchLogsLogGroupArn is set

### IAM Activity Alerts

- [ ] **Verify CloudWatch Events rule for IAM activities**
  ```bash
  aws events list-rules
  ```
  - Look for IAMHighRiskActivityRule in the list

- [ ] **Verify SNS topic for IAM alerts**
  ```bash
  aws sns list-topics
  ```
  - Look for IAMActivityAlerts in the list

- [ ] **Verify subscription to the IAM alerts SNS topic**
  ```bash
  aws sns list-subscriptions-by-topic --topic-arn [topic-arn]
  ```
  - Replace [topic-arn] with the ARN of the IAMActivityAlerts topic
  - Confirm your email address is subscribed

## Additional Verification

### CloudFormation Deployment (if used)

- [ ] **Verify CloudFormation stack status**
  ```bash
  aws cloudformation describe-stacks --stack-name iam-resources
  ```
  - Confirm the stack status is CREATE_COMPLETE

- [ ] **Review stack outputs**
  ```bash
  aws cloudformation describe-stacks --stack-name iam-resources --query 'Stacks[0].Outputs'
  ```
  - Note important output values like role ARNs

## Final Validation

To complete your validation, run the following command to check if your IAM configuration matches best practices:

```bash
./code/scripts/iam-user-lifecycle.sh audit-users
```

You should see:
- No users without MFA (except for newly created service accounts)
- No users with old passwords (> 90 days)
- No users with old access keys (> 90 days)

Additionally, you can use AWS IAM Access Analyzer to identify resources that are shared with external entities:

1. Navigate to the IAM console
2. Select Access Analyzer from the left menu
3. Review any findings listed under the "Active findings" tab

Congratulations! If you've successfully checked off all items in this list, you have implemented a comprehensive identity and access management solution following AWS best practices. 