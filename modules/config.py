"""
Configuration management for JellyDemon.
Adds robust config path resolution so users can run the daemon/CLI from
any directory. Search order:

1) Explicit path provided (file or directory)
2) JELLYDEMON_CONFIG environment variable (file or directory)
3) Current working directory (./config.yml)
4) Directory of this package/script (…/config.yml)
5) Common system locations (/opt/jellydemon/config.yml, ~/.config/jellydemon/config.yml)

The first existing file is used.
"""

import yaml
from pathlib import Path
from typing import Dict, Any, List
from dataclasses import dataclass
import os


@dataclass
class JellyfinConfig:
    """Jellyfin configuration settings."""
    host: str
    port: int
    api_key: str
    use_https: bool = False
    
    @property
    def base_url(self) -> str:
        """Get the base URL for Jellyfin API."""
        protocol = "https" if self.use_https else "http"
        return f"{protocol}://{self.host}:{self.port}"


@dataclass
class NetworkConfig:
    """Network configuration settings."""
    internal_ranges: List[str]
    test_mode: bool = False
    test_external_ranges: List[str] = None


@dataclass
class BandwidthConfig:
    """Bandwidth management configuration."""
    algorithm: str = "equal_split"
    min_per_user: float = 2.0
    max_per_user: float = 50.0
    reserved_bandwidth: float = 10.0
    total_upload_mbps: float = 100.0  # Manual configuration since no router integration


@dataclass
class DaemonConfig:
    """Daemon operation configuration."""
    update_interval: int = 30
    log_level: str = "INFO"
    log_file: str = "jellydemon.log"
    log_max_size: str = "10MB"
    log_backup_count: int = 5
    dry_run: bool = False
    backup_user_settings: bool = True
    pid_file: str = "/tmp/jellydemon.pid"
    # Privacy settings
    anonymize_logs: bool = True
    save_anonymization_map: bool = True
    anonymization_map_file: str = "anonymization_map.json"


class Config:
    """Main configuration class."""
    
    def __init__(self, config_path: str = "config.yml"):
        """Load configuration from YAML file."""
        # Resolve to an actual file path (with fallbacks)
        self.config_path = self._resolve_config_path(config_path)
        self._load_config()
    
    def _load_config(self):
        """Load and parse configuration file."""
        if not self.config_path.exists():
            raise FileNotFoundError(f"Configuration file not found: {self.config_path}")
        
        with open(self.config_path, 'r') as f:
            config_data = yaml.safe_load(f)
            if config_data is None:
                raise ValueError(f"Configuration file is empty or invalid YAML: {self.config_path}")
        
        # Parse configuration sections (with normalization)
        self.jellyfin = JellyfinConfig(**(config_data.get('jellyfin', {}) or {}))
        self.network = NetworkConfig(**(config_data.get('network', {}) or {}))

        # Normalize bandwidth config and store algorithm-specific settings separately
        bw_raw = (config_data.get('bandwidth', {}) or {})
        self._bw_algo_settings = {
            'equal_split': dict(bw_raw.get('equal_split', {}) or {}),
            'priority_based': dict(bw_raw.get('priority_based', {}) or {}),
            'demand_based': dict(bw_raw.get('demand_based', {}) or {}),
        }
        self.bandwidth = self._parse_bandwidth_config(bw_raw, self._bw_algo_settings)

        # Normalize daemon config (e.g., update_interval_seconds -> update_interval)
        daemon_raw = (config_data.get('daemon', {}) or {})
        self.daemon = self._parse_daemon_config(daemon_raw)
        
        self._validate_config()
    
    def _validate_config(self):
        """Validate configuration values."""
        # Validate Jellyfin config
        if not self.jellyfin.host:
            raise ValueError("Jellyfin host is required")
        if not self.jellyfin.api_key:
            raise ValueError("Jellyfin API key is required")
        
        # Validate network config
        if not self.network.internal_ranges:
            raise ValueError("At least one internal IP range is required")
        
        # Validate bandwidth config
        if self.bandwidth.min_per_user >= self.bandwidth.max_per_user:
            raise ValueError("min_per_user must be less than max_per_user")
        if self.bandwidth.total_upload_mbps <= 0:
            raise ValueError("total_upload_mbps must be greater than 0")
    
    def reload(self):
        """Reload configuration from file."""
        self._load_config() 

    # -------------------------
    # Helpers
    # -------------------------
    def _resolve_config_path(self, config_path: str) -> Path:
        """Resolve the configuration file path using a robust search order.

        Accepts a file path or a directory. If a directory is provided, appends
        "config.yml".
        """
        tried: list[Path] = []

        def normalize(p: Path) -> Path:
            # If a directory is given, append config.yml
            if p.is_dir() or (not p.suffix and not p.name.endswith('.yml')):
                return p / "config.yml"
            return p

        # 1) Explicit path
        if config_path:
            p = normalize(Path(config_path).expanduser())
            if p.exists():
                return p
            tried.append(p)

        # 2) Env var
        env_path = os.getenv("JELLYDEMON_CONFIG")
        if env_path:
            p = normalize(Path(env_path).expanduser())
            if p.exists():
                return p
            tried.append(p)

        # 3) Current working directory
        cwd_p = Path.cwd() / "config.yml"
        if cwd_p.exists():
            return cwd_p
        tried.append(cwd_p)

        # 4) Directory of this package/script
        # modules/config.py -> modules -> project root
        pkg_root = Path(__file__).resolve().parent.parent
        pkg_p = pkg_root / "config.yml"
        if pkg_p.exists():
            return pkg_p
        tried.append(pkg_p)

        # 5) Common system locations
        common = [
            Path("/opt/jellydemon/config.yml"),
            Path.home() / ".config" / "jellydemon" / "config.yml",
        ]
        for p in common:
            if p.exists():
                return p
            tried.append(p)

        # Nothing found
        tried_str = "\n - ".join(str(p) for p in tried)
        raise FileNotFoundError(
            "Configuration file not found. Tried the following locations:\n"
            f" - {tried_str}\n"
            "You can set an explicit path with --config or the JELLYDEMON_CONFIG env var."
        )

    def _parse_bandwidth_config(self, bw_raw: Dict[str, Any], algo_settings: Dict[str, Dict[str, Any]]) -> 'BandwidthConfig':
        """Filter and normalize bandwidth config.

        - Ignores unknown top-level keys like 'equal_split', etc.
        - Supports mapping equal_split.min_per_user_mbps -> min_per_user
        """
        allowed_keys = {
            'algorithm',
            'min_per_user',
            'max_per_user',
            'reserved_bandwidth',
            'total_upload_mbps',
        }
        bw_filtered: Dict[str, Any] = {k: v for k, v in bw_raw.items() if k in allowed_keys}

        # Map algorithm-specific overrides if present
        algo = str(bw_filtered.get('algorithm', 'equal_split'))
        if algo == 'equal_split':
            eq = algo_settings.get('equal_split', {}) or {}
            # Allow min_per_user_mbps override
            if 'min_per_user_mbps' in eq and 'min_per_user' not in bw_filtered:
                try:
                    bw_filtered['min_per_user'] = float(eq['min_per_user_mbps'])
                except (TypeError, ValueError):
                    pass

        return BandwidthConfig(**bw_filtered)

    def _parse_daemon_config(self, d_raw: Dict[str, Any]) -> 'DaemonConfig':
        """Normalize daemon config keys to match dataclass fields."""
        mapping = {
            'update_interval_seconds': 'update_interval',
        }
        d_norm: Dict[str, Any] = {}
        for k, v in (d_raw or {}).items():
            target = mapping.get(k, k)
            d_norm[target] = v
        return DaemonConfig(**d_norm)