#!/usr/bin/env python3
"""
Post-installation verification script for JellyDemon
Tests all components to ensure proper installation
"""

import sys
import os
import subprocess
import platform
from pathlib import Path

def test_python_version():
    """Test Python version compatibility."""
    print("🐍 Testing Python version...")
    version = sys.version_info
    if version >= (3, 8):
        print(f"   ✅ Python {version.major}.{version.minor}.{version.micro} (compatible)")
        return True
    else:
        print(f"   ❌ Python {version.major}.{version.minor}.{version.micro} (requires 3.8+)")
        return False

def test_dependencies():
    """Test required dependencies."""
    print("📦 Testing dependencies...")
    dependencies = ['requests', 'pyyaml', 'psutil', 'schedule']
    
    failed = []
    for dep in dependencies:
        try:
            __import__(dep)
            print(f"   ✅ {dep}")
        except ImportError:
            print(f"   ❌ {dep} (missing)")
            failed.append(dep)
    
    if failed:
        print(f"   Install missing dependencies: pip install {' '.join(failed)}")
        return False
    return True

def test_jellydemon_modules():
    """Test JellyDemon module imports."""
    print("🔧 Testing JellyDemon modules...")
    modules = [
        'modules.config',
        'modules.jellyfin_client', 
        'modules.bandwidth_manager',
        'modules.logger',
        'modules.network_utils',
        'modules.anonymizer'
    ]
    
    failed = []
    for module in modules:
        try:
            __import__(module)
            print(f"   ✅ {module}")
        except ImportError as e:
            print(f"   ❌ {module} ({e})")
            failed.append(module)
    
    return len(failed) == 0

def test_configuration():
    """Test configuration file."""
    print("⚙️  Testing configuration...")
    
    # Check if config files exist
    config_file = Path("config.yml")
    example_file = Path("config.example.yml")
    
    if not example_file.exists():
        print("   ❌ config.example.yml not found")
        return False
    print("   ✅ config.example.yml found")
    
    if not config_file.exists():
        print("   ⚠️  config.yml not found (will be created from example)")
        try:
            import shutil
            shutil.copy(example_file, config_file)
            print("   ✅ Created config.yml from example")
        except Exception as e:
            print(f"   ❌ Failed to create config.yml: {e}")
            return False
    else:
        print("   ✅ config.yml found")
    
    # Try to load config
    try:
        from modules.config import Config
        config = Config(str(config_file))
        print("   ✅ Configuration loaded successfully")
        
        # Basic validation
        if hasattr(config, 'jellyfin') and hasattr(config, 'daemon'):
            print("   ✅ Configuration structure valid")
        else:
            print("   ⚠️  Configuration may need review")
        
        return True
    except Exception as e:
        print(f"   ❌ Configuration error: {e}")
        return False

def test_permissions():
    """Test file permissions."""
    print("🔐 Testing permissions...")
    
    files_to_check = ['jellydemon.py', 'modules/', 'config.yml']
    
    for file_path in files_to_check:
        path = Path(file_path)
        if path.exists():
            if os.access(path, os.R_OK):
                print(f"   ✅ {file_path} (readable)")
            else:
                print(f"   ❌ {file_path} (not readable)")
                return False
        else:
            print(f"   ❌ {file_path} (not found)")
            return False
    
    # Check if main script is executable
    main_script = Path("jellydemon.py")
    if platform.system() != "Windows":
        if os.access(main_script, os.X_OK):
            print("   ✅ jellydemon.py (executable)")
        else:
            print("   ⚠️  jellydemon.py (not executable - run: chmod +x jellydemon.py)")
    
    return True

def test_connectivity():
    """Test basic connectivity (if config allows)."""
    print("🌐 Testing connectivity...")
    
    try:
        from modules.config import Config
        config = Config("config.yml")
        
        # Only test if API key is set (not default)
        if (hasattr(config.jellyfin, 'api_key') and 
            config.jellyfin.api_key and 
            config.jellyfin.api_key != "your_jellyfin_api_key_here"):
            
            from modules.jellyfin_client import JellyfinClient
            client = JellyfinClient(config.jellyfin)
            
            if client.test_connection():
                print("   ✅ Jellyfin connection successful")
                return True
            else:
                print("   ❌ Jellyfin connection failed")
                return False
        else:
            print("   ⚠️  Jellyfin API key not configured (skip connectivity test)")
            print("   ℹ️  Edit config.yml with your Jellyfin API key to test connectivity")
            return True
            
    except Exception as e:
        print(f"   ❌ Connectivity test failed: {e}")
        return False

def test_log_directory():
    """Test log directory creation and permissions."""
    print("📝 Testing logging...")
    
    try:
        from modules.logger import setup_logging
        from modules.config import Config
        
        config = Config("config.yml")
        setup_logging(config.daemon)
        print("   ✅ Logging setup successful")
        
        # Test log file creation
        import logging
        logger = logging.getLogger(__name__)
        logger.info("Test log message from verification script")
        print("   ✅ Log file creation successful")
        
        return True
    except Exception as e:
        print(f"   ❌ Logging test failed: {e}")
        return False

def main():
    """Run all verification tests."""
    print("🔍 JellyDemon Installation Verification")
    print("=" * 50)
    print()
    
    tests = [
        ("Python Version", test_python_version),
        ("Dependencies", test_dependencies),
        ("JellyDemon Modules", test_jellydemon_modules),
        ("Configuration", test_configuration),
        ("Permissions", test_permissions),
        ("Logging", test_log_directory),
        ("Connectivity", test_connectivity),
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print()
        try:
            if test_func():
                passed += 1
        except Exception as e:
            print(f"   ❌ {test_name} test crashed: {e}")
    
    print()
    print("=" * 50)
    print(f"📊 Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 Installation verification successful!")
        print()
        print("✅ JellyDemon is ready to use!")
        print()
        print("Next steps:")
        print("1. Edit config.yml with your Jellyfin server details")
        print("2. Run: python jellydemon.py --test")
        print("3. Run: python jellydemon.py --dry-run")
        print("4. Run: python jellydemon.py")
        return True
    else:
        print("❌ Installation verification failed!")
        print()
        print("Please fix the issues above before running JellyDemon.")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
