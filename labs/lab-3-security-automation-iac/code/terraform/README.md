# Terraform Configurations for Security Automation

This directory contains Terraform configurations used in Lab 3: Security Automation with Infrastructure as Code. These configurations are designed to implement security best practices and automate security controls using Terraform.

## Available Configurations

### 1. secure-s3-bucket.tf

A Terraform configuration that creates a secure S3 bucket with multiple security features enabled.

**Features:**
- Server-side encryption with KMS (customer-managed key)
- Public access blocked at all levels
- Versioning enabled for data protection
- Access logging configured to a separate bucket
- Lifecycle policies for managing objects
- Bucket policy enforcing TLS/HTTPS connections
- Object lock configuration for compliance

**Usage:**
```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan -var="bucket_name=your-secure-bucket" -var="aws_region=us-east-1"

# Apply the configuration
terraform apply -var="bucket_name=your-secure-bucket" -var="aws_region=us-east-1"
```

## Using These Configurations

### Prerequisites

Before applying these Terraform configurations:

1. Install Terraform (version 1.0.0 or later recommended):
   ```bash
   terraform --version
   ```

2. Configure AWS credentials:
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="us-east-1"
   ```
   Or use AWS profiles:
   ```bash
   export AWS_PROFILE="your-profile"
   ```

3. Review the configuration to understand what resources will be created.

### Terraform Best Practices

1. **Use Remote State**: For production environments, configure a remote state backend (e.g., S3 with DynamoDB locking):
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "terraform-state-bucket"
       key            = "state/security-resources.tfstate"
       region         = "us-east-1"
       encrypt        = true
       dynamodb_table = "terraform-locks"
     }
   }
   ```

2. **Use Modules**: Consider organizing complex configurations into modules for reusability.

3. **Version Control**: Keep your Terraform configurations in version control.

4. **Workspaces**: Use Terraform workspaces for managing different environments:
   ```bash
   terraform workspace new dev
   terraform workspace new prod
   terraform workspace select dev
   ```

5. **Variables and Outputs**: Use variables for customization and outputs to document important resource attributes.

### Security Considerations

1. **State File Security**: Terraform state contains sensitive information. Always:
   - Use encrypted remote state
   - Restrict access to state files
   - Never commit state files to version control

2. **IAM Permissions**: Use the principle of least privilege for the IAM role/user running Terraform.

3. **Provider Configuration**: Consider using provider configurations that enforce security:
   ```hcl
   provider "aws" {
     region = var.aws_region
     default_tags {
       tags = {
         Environment = var.environment
         ManagedBy   = "terraform"
       }
     }
   }
   ```

4. **Sensitive Variables**: Mark sensitive variables appropriately:
   ```hcl
   variable "db_password" {
     type        = string
     sensitive   = true
     description = "Database password"
   }
   ```

### Working With These Configurations

1. **Customization**: Use variables to customize deployments rather than modifying the main configuration files.

2. **Testing**: Test configurations in a development environment before applying to production.

3. **Validation**: Use the `terraform validate` command to check configuration syntax.

4. **Plan Review**: Always review the plan output before applying changes:
   ```bash
   terraform plan -out=tfplan
   # Review the plan
   terraform apply tfplan
   ```

5. **Destroy Resources**: When you're done, clean up resources:
   ```bash
   terraform destroy
   ```

## Terraform Security Automation

The configurations in this directory demonstrate security automation with Terraform:

1. **Secure Resource Defaults**: Resources are created with secure defaults.

2. **Policy as Code**: Security policies are implemented as code.

3. **Compliance Validation**: Configurations can be validated against compliance requirements.

4. **Infrastructure Testing**: Security tests can be integrated with Terraform workflows.

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Security Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [Terraform Security Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/part3.1.html)

## Troubleshooting

Common issues and solutions:

1. **Authentication Issues**:
   - Verify AWS credentials are correctly configured
   - Check IAM permissions for the resources being created

2. **Resource Conflicts**:
   - Resources may already exist with the same name
   - Use the `terraform import` command to bring existing resources under Terraform management

3. **State Lock Issues**:
   - If using remote state with locking, locks may need to be manually released:
     ```bash
     terraform force-unlock LOCK_ID
     ```

4. **Version Compatibility**:
   - Check Terraform version compatibility with the configurations
   - Check provider version requirements

## Adding New Configurations

When adding new Terraform configurations to this directory, please:

1. Create a separate `.tf` file or directory for each distinct resource collection
2. Include a header comment explaining the purpose of the configuration
3. Define variables with descriptions and defaults where appropriate
4. Add outputs for important resource attributes
5. Update this README with details about the new configuration
6. Include usage examples

If you encounter any issues not covered here, please refer to the Terraform documentation or open an issue in the lab repository. 