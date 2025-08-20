# Contributing to JellyDemon

Thank you for your interest in contributing to JellyDemon! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites
- Python 3.8 or higher
- Access to a Jellyfin server for testing
- Git for version control

### Development Setup
1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/your-username/jellydemon.git
   cd jellydemon
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   pip install pytest pytest-cov flake8 black isort bandit safety
   ```
4. Copy and configure the example config:
   ```bash
   cp config.example.yml config.yml
   # Edit config.yml with your Jellyfin details
   ```

## 📋 How to Contribute

### Reporting Issues
- Use the issue templates provided
- Include relevant system information
- Provide anonymized logs when possible
- Search existing issues before creating new ones

### Suggesting Features
- Use the feature request template
- Explain the use case and motivation
- Consider backward compatibility
- Think about security implications

### Submitting Changes

#### 1. Create a Feature Branch
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

#### 2. Make Your Changes
- Follow the coding standards (see below)
- Add tests for new functionality
- Update documentation as needed
- Ensure security considerations are addressed

#### 3. Test Your Changes
```bash
# Run the test suite
pytest test_jellydemon.py -v

# Check code formatting
black --check .
isort --check-only .

# Run linting
flake8 .

# Security checks
bandit -r .
safety check
```

#### 4. Commit Your Changes
- Use clear, descriptive commit messages
- Reference issue numbers when applicable
- Keep commits focused and atomic

```bash
git add .
git commit -m "Add bandwidth throttling feature (fixes #123)"
```

#### 5. Push and Create Pull Request
```bash
git push origin feature/your-feature-name
```
Then create a pull request using the provided template.

## 🛠 Coding Standards

### Python Style
- Follow PEP 8 style guidelines
- Use `black` for code formatting with default settings
- Use `isort` for import sorting
- Maximum line length: 127 characters
- Use type hints where beneficial

### Code Organization
- Keep functions focused and single-purpose
- Use descriptive variable and function names
- Add docstrings for all public functions and classes
- Organize imports: standard library, third-party, local modules

### Example Code Style
```python
from typing import Dict, List, Optional
import logging

from modules.config import Config


class BandwidthManager:
    """Manages bandwidth allocation for Jellyfin streams."""
    
    def __init__(self, config: Config) -> None:
        """Initialize the bandwidth manager.
        
        Args:
            config: The application configuration
        """
        self.config = config
        self.logger = logging.getLogger(__name__)
    
    def calculate_allocation(self, active_streams: List[Dict]) -> Dict[str, int]:
        """Calculate bandwidth allocation for active streams.
        
        Args:
            active_streams: List of currently active streaming sessions
            
        Returns:
            Dictionary mapping session IDs to allocated bandwidth in Kbps
        """
        # Implementation here
        pass
```

### Testing
- Write unit tests for all new functionality
- Aim for good test coverage (>80%)
- Use descriptive test names that explain what is being tested
- Test both happy path and error conditions
- Mock external dependencies (Jellyfin API calls)

### Security Guidelines
- Never hardcode sensitive information
- Validate all inputs
- Use the anonymization system for logging user data
- Follow principle of least privilege
- Consider security implications of new features

## 📝 Documentation

### Code Documentation
- Add docstrings to all public functions and classes
- Include type hints for better code clarity
- Comment complex logic or algorithms
- Keep comments up-to-date with code changes

### User Documentation
- Update README.md for user-facing changes
- Update configuration documentation
- Include examples in documentation
- Consider security implications in documentation

## 🔒 Security Considerations

### Sensitive Data
- Use the built-in anonymization system
- Never log API keys, passwords, or personal information
- Be careful with IP addresses and usernames
- Test anonymization thoroughly

### Input Validation
- Validate configuration parameters
- Sanitize user inputs
- Handle errors gracefully
- Avoid path traversal vulnerabilities

### Dependencies
- Keep dependencies up-to-date
- Check for known vulnerabilities with `safety check`
- Minimize external dependencies
- Review new dependencies carefully

## 🧪 Testing Guidelines

### Unit Tests
- Test individual functions and methods
- Mock external dependencies
- Test error conditions
- Use descriptive test names

```python
def test_bandwidth_manager_calculates_equal_split_correctly():
    """Test that equal split algorithm divides bandwidth evenly."""
    # Test implementation
```

### Integration Tests
- Test component interactions
- Use test configuration
- Mock network calls when possible
- Test with anonymization enabled

## 📦 Release Process

### Version Numbering
- Follow semantic versioning (MAJOR.MINOR.PATCH)
- Update version in `setup.py`
- Tag releases in git
- Update changelog

### Pre-release Checklist
- [ ] All tests pass
- [ ] Security scan passes
- [ ] Documentation updated
- [ ] Version number updated
- [ ] Changelog updated

## ❓ Getting Help

### Questions
- Create a question issue using the template
- Check existing documentation first
- Be specific about your setup and problem

### Discussion
- Use GitHub Discussions for general questions
- Join development discussions
- Share ideas and feedback

## 📄 License

By contributing to JellyDemon, you agree that your contributions will be licensed under the same license as the project.

## 🙏 Recognition

Contributors will be recognized in the project documentation and releases. Thank you for helping make JellyDemon better!
