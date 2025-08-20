#!/usr/bin/env python3
"""
JellyDemon Health Check
Quick verification that all components are working
"""

import os
import sys
import importlib.util
from pathlib import Path


def check_file_exists(file_path, description):
    """Check if a file exists."""
    if os.path.exists(file_path):
        print(f"✓ {description}: {file_path}")
        return True
    else:
        print(f"✗ {description}: {file_path} (missing)")
        return False


def check_module_import(module_name, file_path):
    """Check if a Python module can be imported."""
    try:
        # Add the modules directory to path
        sys.path.insert(0, str(Path(__file__).parent / "modules"))
        
        if file_path:
            spec = importlib.util.spec_from_file_location(module_name, file_path)
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
        else:
            __import__(module_name)
        
        print(f"✓ Module {module_name}: importable")
        return True
    except Exception as e:
        print(f"✗ Module {module_name}: {e}")
        return False


def check_dependencies():
    """Check if required dependencies are available."""
    required_modules = ['requests', 'yaml']
    all_good = True
    
    for module in required_modules:
        try:
            __import__(module)
            print(f"✓ Dependency {module}: available")
        except ImportError:
            print(f"✗ Dependency {module}: missing")
            all_good = False
    
    return all_good


def main():
    """Run health checks."""
    print("🏥 JellyDemon Health Check")
    print("=" * 40)
    
    issues = []
    
    # Check core files
    print("\n📁 Core Files:")
    core_files = [
        ("jellydemon.py", "Main daemon"),
        ("config.example.yml", "Example config"),
        ("requirements.txt", "Dependencies"),
        ("README.md", "Documentation"),
    ]
    
    for file_path, description in core_files:
        if not check_file_exists(file_path, description):
            issues.append(f"Missing {description}")
    
    # Check module files
    print("\n🧩 Modules:")
    module_files = [
        ("modules/__init__.py", "Module package"),
        ("modules/config.py", "Configuration"),
        ("modules/jellyfin_client.py", "Jellyfin client"),
        ("modules/bandwidth_manager.py", "Bandwidth manager"),
        ("modules/logger.py", "Logging"),
        ("modules/network_utils.py", "Network utilities"),
        ("modules/log_sharer.py", "Log sharing"),
    ]
    
    for file_path, description in module_files:
        if not check_file_exists(file_path, description):
            issues.append(f"Missing {description}")
    
    # Check module imports
    print("\n🔌 Module Imports:")
    module_imports = [
        ("config", "modules/config.py"),
        ("jellyfin_client", "modules/jellyfin_client.py"),
        ("bandwidth_manager", "modules/bandwidth_manager.py"),
        ("logger", "modules/logger.py"),
        ("network_utils", "modules/network_utils.py"),
        ("log_sharer", "modules/log_sharer.py"),
    ]
    
    for module_name, file_path in module_imports:
        if not check_module_import(module_name, file_path):
            issues.append(f"Cannot import {module_name}")
    
    # Check dependencies
    print("\n📦 Dependencies:")
    if not check_dependencies():
        issues.append("Missing required dependencies")
    
    # Check install scripts
    print("\n🚀 Install Scripts:")
    install_files = [
        ("install.sh", "Linux installer"),
        ("install.ps1", "Windows installer"),
        ("configure.sh", "Linux configurator"),
        ("configure.ps1", "Windows configurator"),
    ]
    
    for file_path, description in install_files:
        if not check_file_exists(file_path, description):
            issues.append(f"Missing {description}")
    
    # Check Docker files
    print("\n🐳 Docker Files:")
    docker_files = [
        ("Dockerfile", "Docker image definition"),
        ("docker-compose.yml", "Docker compose"),
        (".dockerignore", "Docker ignore"),
    ]
    
    for file_path, description in docker_files:
        if not check_file_exists(file_path, description):
            issues.append(f"Missing {description}")
    
    # Summary
    print("\n" + "=" * 40)
    
    if not issues:
        print("🎉 All checks passed! JellyDemon is ready.")
        print("\nNext steps:")
        print("1. Copy config.example.yml to config.yml")
        print("2. Edit config.yml with your Jellyfin details")
        print("3. Run: python jellydemon.py --dry-run")
        return 0
    else:
        print(f"❌ Found {len(issues)} issues:")
        for issue in issues:
            print(f"  • {issue}")
        print("\nPlease fix these issues before using JellyDemon.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
