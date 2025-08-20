"""
Logging configuration for JellyDemon with privacy anonymization.
"""

import logging
import logging.handlers
from pathlib import Path
from typing import TYPE_CHECKING

from modules.anonymizer import LogAnonymizer, AnonymizingFormatter

if TYPE_CHECKING:
    from .config import Config


def setup_logging(config: 'Config') -> logging.Logger:
    """Setup logging configuration with anonymization."""
    logger = logging.getLogger('jellydemon')
    
    # Set log level
    log_level = getattr(logging, config.daemon.log_level.upper(), logging.INFO)
    logger.setLevel(log_level)
    
    # Clear any existing handlers
    logger.handlers.clear()
    
    # Initialize anonymizer
    anonymizer = LogAnonymizer(enabled=config.daemon.anonymize_logs)
    
    # Create formatter with anonymization
    if config.daemon.anonymize_logs:
        formatter = AnonymizingFormatter(
            anonymizer,
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        # Log anonymization status
        print(f"🔒 Log anonymization enabled - privacy protection active")
        if config.daemon.save_anonymization_map:
            print(f"📋 Anonymization mapping will be saved to: {config.daemon.anonymization_map_file}")
    else:
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        print("⚠️ Log anonymization disabled - sensitive data may be logged")
    
    # Console handler
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    # File handler with rotation
    if config.daemon.log_file:
        log_file = Path(config.daemon.log_file)
        
        # Parse max size (convert "10MB" to bytes)
        max_size = config.daemon.log_max_size
        if max_size.upper().endswith('MB'):
            max_bytes = int(max_size[:-2]) * 1024 * 1024
        elif max_size.upper().endswith('KB'):
            max_bytes = int(max_size[:-2]) * 1024
        else:
            max_bytes = int(max_size)
        
        file_handler = logging.handlers.RotatingFileHandler(
            log_file,
            maxBytes=max_bytes,
            backupCount=config.daemon.log_backup_count
        )
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
    
    # Don't propagate to root logger
    logger.propagate = False
    
    # Store anonymizer in logger for later access
    logger.anonymizer = anonymizer
    
    return logger 