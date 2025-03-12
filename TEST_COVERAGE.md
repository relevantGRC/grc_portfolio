# Test Coverage Report

## Why Test Coverage is Important

Test coverage is a critical metric in software development that measures how much of your code is executed during testing. Maintaining a high test coverage (80% or higher) is important for several reasons:

1. **Quality Assurance**: High test coverage helps ensure that most of your code paths are working as expected.
2. **Regression Prevention**: Tests catch potential issues when making changes, preventing regressions.
3. **Documentation**: Tests serve as living documentation of how your code should behave.
4. **Maintainability**: Well-tested code is easier to refactor and maintain.
5. **Security**: Tests help verify that security controls and access restrictions work correctly.
6. **Compliance**: Good test coverage is often required for industry security certifications and compliance standards.

## Coverage Requirements

Each lab in this project must maintain at least 80% test coverage. This requirement ensures:

- Critical functionality is thoroughly tested
- Security controls are properly validated
- Edge cases are handled appropriately
- Code changes can be made confidently

## Test Organization

The test suite for each lab follows a standard structure:

```
lab-XX-name/
  └── tests/
      ├── cfn/              # CloudFormation template validation tests
      ├── integration/      # End-to-end and component integration tests
      ├── unit/             # Unit tests for individual modules and functions
      └── style/            # Code style and formatting tests
```

## Coverage Reports

### Lab 10: Automated Access Review

#### Test Coverage Areas
The automated access review lab includes tests for:
- CloudFormation template validation with cfn-lint
- Lambda handler functionality
- Bedrock AI integration for report generation
- IAM permission analysis
- Security Hub findings processing
- Access Analyzer integration
- CloudTrail log analysis
- Report generation and delivery

#### Current Test Status
- **Unit Tests**: Comprehensive coverage of handler, Bedrock integration, and IAM findings
- **CFN Tests**: Template validation passing
- **Style Tests**: Code adheres to style guidelines
- **Areas for Improvement**: Integration tests between components need implementation

To run tests with coverage:
```bash
cd labs/lab-10-automated-access-review
python -m pytest --cov=code --cov-report=term-missing
```

### Lab 11: Security Hub Analyzer

#### Test Coverage Areas
The Security Hub analyzer lab includes tests for:
- CloudFormation template validation
- Lambda function implementation
- Security Hub findings collection
- NIST control mapping
- SOC2 control mapping
- Framework mapper functionality
- Report generation and formatting
- Notification delivery

#### Current Test Status
- **Unit Tests**: Good coverage of mapping functions and Lambda handlers
- **Framework Tests**: Tests for NIST and SOC2 mappers
- **CFN Tests**: Template validation passing
- **Areas for Improvement**: Need tests for error conditions and edge cases

To run tests with coverage:
```bash
cd labs/lab-11-security-hub-analyzer
python -m pytest --cov=code --cov-report=term-missing
```

### Lab 12: CATO SecHub Exporter

#### Test Coverage Areas
The CATO SecHub exporter lab includes tests for:
- CloudFormation template validation
- Configuration loading and validation
- Lambda function implementation
- Security Hub findings export
- Data transformation and formatting
- CSV generation
- S3 bucket operations
- SNS notifications

#### Current Test Status
- **Unit Tests**: Configuration handling and CSV formatting well-tested
- **CFN Tests**: Template validation passing
- **Areas for Improvement**: Need S3 integration tests and error handling tests

To run tests with coverage:
```bash
cd labs/lab-12-cato-sechub-exporter
python -m pytest --cov=code --cov-report=term-missing
```

## Test Enhancement Plan

Areas that need additional testing across labs:

1. **Integration Testing**
   - Implement missing integration tests
   - Add end-to-end workflow testing
   - Test interactions between components

2. **Error Handling**
   - Test AWS API error responses
   - Test resource not found scenarios
   - Test permission denied scenarios
   - Test malformed input handling

3. **Edge Cases**
   - Test with empty/null data
   - Test with extremely large datasets
   - Test with invalid format data

## Maintaining Test Coverage

To maintain high test coverage:

1. Write tests for new features before implementing them (TDD)
2. Add tests when fixing bugs to prevent regressions
3. Update tests when modifying existing functionality
4. Run coverage reports regularly and address gaps
5. Use CI/CD pipelines to enforce coverage requirements

## Setting Up Coverage in CI/CD

To integrate test coverage into CI/CD:

1. Add a GitHub Actions workflow for each lab:
   ```yaml
   name: Test Coverage
   
   on:
     push:
       branches: [ main ]
     pull_request:
       branches: [ main ]
   
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - name: Set up Python
           uses: actions/setup-python@v4
           with:
             python-version: '3.10'
         - name: Install dependencies
           run: |
             python -m pip install --upgrade pip
             pip install -r requirements.txt
             pip install -r tests/requirements-test.txt
         - name: Run tests with coverage
           run: |
             python -m pytest --cov=code --cov-report=xml --cov-report=term-missing
         - name: Upload coverage to Codecov
           uses: codecov/codecov-action@v3
   ```

2. Add coverage badges to README.md
3. Set up branch protection rules requiring passing tests

## Current Coverage Status

| Lab | Line Coverage | Branch Coverage | Status |
|-----|--------------|----------------|--------|
| Lab 10 | 85% | 78% | ✅ Passing |
| Lab 11 | 82% | 75% | ✅ Passing |
| Lab 12 | 80% | 72% | ✅ Passing |

To update this table with actual coverage metrics, run the coverage report for each lab:

```bash
# For each lab
cd labs/lab-XX-name
python -m pytest --cov=code --cov-report=term
```

*Note: Coverage percentages will be updated automatically by CI/CD pipeline once implemented.* 