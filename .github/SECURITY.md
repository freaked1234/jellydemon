# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in JellyDemon, please report it responsibly:

### 🔒 Private Reporting (Preferred)

1. **Email**: Send details to [your-email@example.com]
2. **GitHub Security**: Use GitHub's private vulnerability reporting feature
3. **Include**: 
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if known)

### ⏱️ Response Timeline

- **Initial response**: Within 48 hours
- **Assessment**: Within 1 week
- **Fix timeline**: Depends on severity
  - Critical: Within 24-48 hours
  - High: Within 1 week
  - Medium: Within 2 weeks
  - Low: Next scheduled release

### 🛡️ Security Considerations

JellyDemon handles sensitive information:

- **Jellyfin API keys**: Stored in configuration files
- **User data**: Usernames, IP addresses, session information
- **Network information**: Internal IP ranges and bandwidth data

### 🔐 Built-in Privacy Protection

- **Log anonymization**: Automatically anonymizes user data in logs
- **Configuration security**: Sensitive config files excluded from git
- **API key protection**: Keys are masked in logs and error messages

### 📋 Security Best Practices

When using JellyDemon:

1. **Protect API keys**: Never share or commit Jellyfin API keys
2. **Use anonymization**: Enable log anonymization for public bug reports
3. **Secure deployment**: Run with minimal required permissions
4. **Regular updates**: Keep JellyDemon and dependencies updated
5. **Monitor logs**: Review logs for suspicious activity

### 🎯 Out of Scope

- Issues in Jellyfin itself (report to Jellyfin project)
- Network infrastructure vulnerabilities
- Operating system or Python interpreter issues
- Social engineering attacks

Thank you for helping keep JellyDemon secure!
