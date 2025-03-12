# Lab 6: Data Security - Advanced Challenges

After completing the main lab, try these advanced challenges to further enhance your data security skills. Each challenge builds upon the foundation you've established in the lab and introduces more complex scenarios and solutions.

## Challenge 1: Multi-Region Data Replication with Encryption

**Objective:** Implement secure cross-region replication for your S3 bucket while maintaining encryption and access controls.

**Tasks:**
1. Configure cross-region replication for your S3 bucket to a second AWS region
2. Ensure that encryption is maintained during replication
3. Create a KMS multi-region key for seamless encryption across regions
4. Implement appropriate IAM roles and policies for the replication
5. Set up monitoring for replication status and failures

**Success Criteria:**
- Objects are successfully replicated to the destination bucket
- Encryption is maintained during replication
- Tags and metadata are preserved
- Access controls are consistent across regions
- Monitoring is in place for replication events

## Challenge 2: Data Loss Prevention (DLP) Implementation

**Objective:** Implement a comprehensive DLP solution to prevent sensitive data exfiltration.

**Tasks:**
1. Extend your Macie configuration to scan all S3 buckets in your account
2. Create custom data identifiers for organization-specific sensitive data
3. Implement a Lambda function that triggers when Macie finds sensitive data
4. Configure the Lambda to automatically quarantine files with sensitive data
5. Set up notifications for security teams when sensitive data is detected

**Success Criteria:**
- Custom data identifiers successfully detect organization-specific patterns
- Files with sensitive data are automatically moved to a quarantine bucket
- Security teams receive notifications with details about the findings
- The solution works for both existing data and newly uploaded data
- False positives are minimized through proper configuration

## Challenge 3: Database Activity Monitoring

**Objective:** Implement comprehensive monitoring for database activity to detect suspicious behavior.

**Tasks:**
1. Enable Database Activity Streams for your RDS instance
2. Configure the streams to send events to Kinesis
3. Create a Lambda function to analyze the database activity
4. Set up alerts for suspicious activities such as:
   - Excessive data retrieval
   - Access to sensitive tables
   - Unusual query patterns
   - Access outside normal business hours
5. Create a CloudWatch dashboard for database activity monitoring

**Success Criteria:**
- Database activity is successfully captured and analyzed
- Alerts are triggered for suspicious activities
- The dashboard provides clear visibility into database access patterns
- The solution has minimal performance impact on the database
- False positives are minimized through proper configuration

## Challenge 4: Secure Data Sharing with External Partners

**Objective:** Implement a secure mechanism for sharing sensitive data with external partners.

**Tasks:**
1. Create a dedicated S3 bucket for external sharing
2. Implement a Lambda function that processes files before sharing:
   - Validates file content
   - Removes sensitive metadata
   - Applies appropriate encryption
   - Adds watermarks or tracking information
3. Set up pre-signed URLs with appropriate expiration times
4. Implement access logging and notifications for all access events
5. Create a rotation mechanism for access credentials

**Success Criteria:**
- External partners can access only the specific files shared with them
- All access is logged and monitored
- Files are properly processed before sharing
- Access expires after the designated time period
- The solution is user-friendly while maintaining security

## Challenge 5: Automated Data Classification

**Objective:** Implement an automated system to classify data based on content analysis.

**Tasks:**
1. Create a Lambda function that analyzes files uploaded to S3
2. Use Amazon Comprehend to detect sensitive information types
3. Automatically apply appropriate tags based on the content analysis
4. Implement appropriate encryption and access controls based on classification
5. Create a workflow for handling classification conflicts or uncertainties

**Success Criteria:**
- Files are automatically classified based on content
- Appropriate tags are applied to reflect classification
- Encryption and access controls are adjusted based on classification
- The system handles edge cases and uncertainties gracefully
- Classification accuracy is high with minimal false positives

## Challenge 6: Encryption Key Rotation and Management

**Objective:** Implement a comprehensive key management solution with automated rotation and monitoring.

**Tasks:**
1. Create a custom key rotation solution that goes beyond the AWS default
2. Implement a mechanism to re-encrypt existing data with new keys
3. Set up monitoring for key usage and access attempts
4. Create a key recovery process for emergency situations
5. Implement a key hierarchy with different keys for different purposes

**Success Criteria:**
- Keys are rotated according to schedule
- Existing data is re-encrypted with new keys
- Key usage is properly monitored and logged
- Recovery processes are tested and functional
- The key hierarchy provides appropriate separation of duties

## Challenge 7: Data Tokenization for Sensitive Information

**Objective:** Implement a tokenization solution to protect sensitive data while maintaining application functionality.

**Tasks:**
1. Create a tokenization service using Lambda and DynamoDB
2. Modify sample applications to use tokenization for sensitive fields
3. Implement appropriate access controls for the tokenization service
4. Set up monitoring and logging for tokenization operations
5. Create a mechanism for authorized detokenization

**Success Criteria:**
- Sensitive data is successfully tokenized
- Applications function correctly with tokenized data
- Only authorized users/services can detokenize data
- The solution is scalable and performs well under load
- All tokenization operations are properly logged

## Challenge 8: Secure Data Analytics Pipeline

**Objective:** Build a secure data analytics pipeline that maintains data security throughout the process.

**Tasks:**
1. Create a data pipeline using AWS Glue or Step Functions
2. Implement encryption for data at all stages of the pipeline
3. Set up appropriate access controls for each component
4. Create a mechanism to anonymize or pseudonymize sensitive data
5. Implement monitoring and logging throughout the pipeline

**Success Criteria:**
- Data remains encrypted throughout the pipeline
- Access controls enforce least privilege
- Sensitive data is properly anonymized for analytics
- The pipeline is monitored for security events
- The solution balances security with analytics functionality

## Challenge 9: Secure Multi-Account Data Strategy

**Objective:** Implement a secure data strategy across multiple AWS accounts.

**Tasks:**
1. Set up a dedicated data security account
2. Implement cross-account access for centralized management
3. Create a consistent tagging and classification strategy across accounts
4. Implement centralized monitoring and alerting
5. Create automated remediation that works across accounts

**Success Criteria:**
- Data security is consistently enforced across all accounts
- Centralized management simplifies administration
- Monitoring provides visibility across the entire organization
- Remediation works effectively across account boundaries
- The solution scales as new accounts are added

## Challenge 10: Regulatory Compliance Implementation

**Objective:** Extend your data security implementation to meet specific regulatory requirements (GDPR, HIPAA, PCI DSS, etc.).

**Tasks:**
1. Choose a specific regulatory framework
2. Identify the data security requirements for that framework
3. Implement additional controls to meet those requirements
4. Create documentation and evidence for compliance audits
5. Set up regular compliance checks and reporting

**Success Criteria:**
- All regulatory requirements are addressed
- Documentation clearly demonstrates compliance
- Regular checks verify ongoing compliance
- The solution adapts to changes in regulatory requirements
- The implementation balances compliance with operational needs

## Submission Guidelines

For each challenge you complete:

1. Document your solution with architecture diagrams and explanations
2. Provide code samples and configuration files (with sensitive information redacted)
3. Include screenshots demonstrating the implementation
4. Explain any challenges encountered and how you overcame them
5. Discuss potential improvements or alternative approaches

## Evaluation Criteria

Your solutions will be evaluated based on:

1. **Security Effectiveness:** How well the solution addresses the security objectives
2. **Implementation Quality:** Code quality, architecture, and adherence to best practices
3. **Completeness:** Whether all aspects of the challenge were addressed
4. **Innovation:** Creative approaches to solving complex problems
5. **Documentation:** Clarity and completeness of documentation
6. **Operational Viability:** How practical the solution is for real-world implementation