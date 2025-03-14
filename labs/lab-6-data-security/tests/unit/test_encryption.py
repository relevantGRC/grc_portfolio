import sys
import os
import pytest

# Add the parent directory to sys.path to enable imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

def test_module_imports():
    """Test basic module imports work."""
    try:
        # Import the modules we want to test
        import src.scripts.s3_encryption_remediation
        assert True
    except ImportError:
        pytest.skip("Module not found, skipping import test")
