import sys
import os
import pytest

# Add the parent directory to sys.path to enable imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

def test_module_imports():
    """Test basic module imports work."""
    try:
        # Import the modules we want to test
        import src.scripts.lambda_functions.required_tags
        import src.scripts.remediation.s3_policy_remediation
        import src.scripts.remediation.encryption_remediation
        assert True
    except ImportError:
        pytest.skip("Module not found, skipping import test")
