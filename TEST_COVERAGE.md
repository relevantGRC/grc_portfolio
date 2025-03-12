# Test Coverage Report

## Why Test Coverage is Important

Test coverage is a critical metric in software development that measures how much of your code is executed during testing. Maintaining a high test coverage (80% or higher) is important for several reasons:

1. **Quality Assurance**: High test coverage helps ensure that most of your code paths are working as expected.
2. **Regression Prevention**: Tests catch potential issues when making changes, preventing regressions.
3. **Documentation**: Tests serve as living documentation of how your code should behave.
4. **Maintainability**: Well-tested code is easier to refactor and maintain.
5. **Security**: Tests help verify that security controls and access restrictions work correctly.

## Coverage Requirements

Each lab in this project must maintain at least 80% test coverage. This requirement ensures:

- Critical functionality is thoroughly tested
- Security controls are properly validated
- Edge cases are handled appropriately
- Code changes can be made confidently

## Coverage Reports

### Lab 10: Automated Access Review

The automated access review lab includes tests for:
- CloudFormation template validation
- Lambda function integration
- IAM permission checks
- Security Hub findings analysis
- Access Analyzer integration
- CloudTrail log analysis
- Report generation and delivery

To run tests with coverage:
```bash
cd labs/lab-10-automated-access-review
python -m pytest --cov=code --cov-report=term-missing
```

### Lab 11: Security Hub Analyzer

The Security Hub analyzer lab includes tests for:
- CloudFormation template validation
- Lambda function integration
- Security Hub findings collection
- Finding analysis and categorization
- Report generation
- Notification delivery

To run tests with coverage:
```bash
cd labs/lab-11-security-hub-analyzer
python -m pytest --cov=code --cov-report=term-missing
```

### Lab 12: CATO SecHub Exporter

The CATO SecHub exporter lab includes tests for:
- CloudFormation template validation
- Lambda function integration
- Security Hub findings export
- Data transformation
- S3 bucket operations
- SNS notifications

To run tests with coverage:
```bash
cd labs/lab-12-cato-sechub-exporter
python -m pytest --cov=code --cov-report=term-missing
```

## Maintaining Test Coverage

To maintain high test coverage:

1. Write tests for new features before implementing them (TDD)
2. Add tests when fixing bugs to prevent regressions
3. Update tests when modifying existing functionality
4. Run coverage reports regularly and address gaps
5. Use CI/CD pipelines to enforce coverage requirements

## Coverage Reports

Coverage reports are generated automatically by GitHub Actions on each push and pull request. You can also generate them locally using the commands above.

### Current Coverage Status

| Lab | Coverage | Status |
|-----|----------|--------|
| Lab 10 | TBD | 🔄 |
| Lab 11 | TBD | 🔄 |
| Lab 12 | TBD | 🔄 |

*Note: Coverage percentages will be updated automatically by CI/CD pipeline.* 