"""
Anonymization utilities for protecting user privacy in logs.
"""

import re
import hashlib
import ipaddress
from typing import Dict, Set
import logging


class LogAnonymizer:
    """Anonymizes sensitive information in log messages."""
    
    def __init__(self, enabled: bool = True):
        """Initialize the anonymizer."""
        self.enabled = enabled
        self.username_map: Dict[str, str] = {}
        self.ip_map: Dict[str, str] = {}
        self.session_map: Dict[str, str] = {}
        self.user_counter = 0
        self.ip_counter = 0
        self.session_counter = 0
        
        # Regex patterns for detecting sensitive information
        self.username_patterns = [
            r'user\s+([A-Za-z0-9_.-]+)',  # "user username123"
            r'User:\s*([A-Za-z0-9_.-]+)', # "User: username123"
            r'username\s*[:=]\s*([A-Za-z0-9_.-]+)', # "username: username123"
            r'"Name":\s*"([^"]+)"',       # JSON: "Name": "username"
            r'Set user ([A-Za-z0-9_.-]+)', # "Set user username123"
            r'for user ([A-Za-z0-9_.-]+)', # "for user username123"
        ]
        
        self.ip_patterns = [
            r'\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b',
            r'\b(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\b',  # IPv6
        ]
        
        self.session_patterns = [
            r'session[_\s]+([a-zA-Z0-9-]+)',  # "session abc123"
            r'Session[_\s]+([a-zA-Z0-9-]+)',  # "Session abc123"
        ]
        
        # API key patterns
        self.api_key_patterns = [
            r'api[_\s]*key[_\s]*[:=]\s*([a-zA-Z0-9]+)',
            r'Token[_\s]*[:=]\s*([a-zA-Z0-9]+)',
        ]
    
    def anonymize_username(self, username: str) -> str:
        """Anonymize a username consistently."""
        if not self.enabled or not username:
            return username
            
        if username not in self.username_map:
            self.user_counter += 1
            self.username_map[username] = f"User-{self.user_counter:03d}"
        
        return self.username_map[username]
    
    def anonymize_ip(self, ip_str: str) -> str:
        """Anonymize an IP address while preserving network structure."""
        if not self.enabled or not ip_str:
            return ip_str
            
        if ip_str not in self.ip_map:
            try:
                ip = ipaddress.ip_address(ip_str)
                
                if ip.is_private:
                    # For private IPs, anonymize but keep structure
                    if ip.version == 4:
                        # Keep first two octets for network identification
                        parts = ip_str.split('.')
                        if parts[0] == '192' and parts[1] == '168':
                            anonymized = f"192.168.xxx.{len(self.ip_map) + 1}"
                        elif parts[0] == '10':
                            anonymized = f"10.xxx.xxx.{len(self.ip_map) + 1}"
                        elif parts[0] == '172':
                            anonymized = f"172.16.xxx.{len(self.ip_map) + 1}"
                        else:
                            anonymized = f"Private-IP-{len(self.ip_map) + 1}"
                    else:
                        anonymized = f"Private-IPv6-{len(self.ip_map) + 1}"
                else:
                    # For public IPs, just use a counter
                    self.ip_counter += 1
                    anonymized = f"External-IP-{self.ip_counter:03d}"
                    
                self.ip_map[ip_str] = anonymized
                
            except ValueError:
                # Invalid IP, treat as generic identifier
                self.ip_counter += 1
                self.ip_map[ip_str] = f"IP-{self.ip_counter:03d}"
        
        return self.ip_map[ip_str]
    
    def anonymize_session(self, session_id: str) -> str:
        """Anonymize a session ID."""
        if not self.enabled or not session_id:
            return session_id
            
        if session_id not in self.session_map:
            self.session_counter += 1
            self.session_map[session_id] = f"Session-{self.session_counter:03d}"
        
        return self.session_map[session_id]
    
    def anonymize_api_key(self, api_key: str) -> str:
        """Anonymize API keys."""
        if not self.enabled or not api_key:
            return api_key
        
        # Create a consistent hash for the API key
        hash_obj = hashlib.md5(api_key.encode())
        short_hash = hash_obj.hexdigest()[:8]
        return f"[API-KEY-{short_hash}]"
    
    def anonymize_message(self, message: str) -> str:
        """Anonymize a complete log message."""
        if not self.enabled:
            return message
        
        anonymized = message
        
        # Anonymize usernames
        for pattern in self.username_patterns:
            def replace_username(match):
                username = match.group(1)
                anon_username = self.anonymize_username(username)
                return match.group(0).replace(username, anon_username)
            
            anonymized = re.sub(pattern, replace_username, anonymized, flags=re.IGNORECASE)
        
        # Anonymize IP addresses
        for pattern in self.ip_patterns:
            def replace_ip(match):
                ip = match.group(0)
                return self.anonymize_ip(ip)
            
            anonymized = re.sub(pattern, replace_ip, anonymized)
        
        # Anonymize session IDs
        for pattern in self.session_patterns:
            def replace_session(match):
                session_id = match.group(1)
                anon_session = self.anonymize_session(session_id)
                return match.group(0).replace(session_id, anon_session)
            
            anonymized = re.sub(pattern, replace_session, anonymized, flags=re.IGNORECASE)
        
        # Anonymize API keys
        for pattern in self.api_key_patterns:
            def replace_api_key(match):
                api_key = match.group(1)
                anon_key = self.anonymize_api_key(api_key)
                return match.group(0).replace(api_key, anon_key)
            
            anonymized = re.sub(pattern, replace_api_key, anonymized, flags=re.IGNORECASE)
        
        return anonymized
    
    def get_mapping_summary(self) -> Dict[str, Dict[str, str]]:
        """Get a summary of anonymization mappings for debugging."""
        return {
            'usernames': dict(self.username_map),
            'ips': dict(self.ip_map),
            'sessions': dict(self.session_map),
            'stats': {
                'total_users': len(self.username_map),
                'total_ips': len(self.ip_map),
                'total_sessions': len(self.session_map)
            }
        }
    
    def save_mapping(self, filepath: str) -> None:
        """Save anonymization mapping to file for developer reference."""
        import json
        mapping = self.get_mapping_summary()
        with open(filepath, 'w') as f:
            json.dump(mapping, f, indent=2)


class AnonymizingFormatter(logging.Formatter):
    """Custom log formatter that anonymizes sensitive information."""
    
    def __init__(self, anonymizer: LogAnonymizer, *args, **kwargs):
        """Initialize with an anonymizer instance."""
        super().__init__(*args, **kwargs)
        self.anonymizer = anonymizer
    
    def format(self, record):
        """Format the log record with anonymization."""
        # Get the original formatted message
        formatted = super().format(record)
        
        # Anonymize the message
        if self.anonymizer.enabled:
            formatted = self.anonymizer.anonymize_message(formatted)
        
        return formatted
