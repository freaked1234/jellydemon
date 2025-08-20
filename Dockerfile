FROM python:3.11-slim

# Set metadata
LABEL maintainer="freaked1234"
LABEL description="JellyDemon - Jellyfin Bandwidth Management Daemon"
LABEL version="1.0.0"

# Create app user
RUN groupadd -r jellydemon && useradd --no-log-init -r -g jellydemon jellydemon

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY jellydemon.py .
COPY modules/ modules/
COPY config.example.yml .

# Create directories for logs and config
RUN mkdir -p /app/logs /app/config

# Set proper permissions
RUN chown -R jellydemon:jellydemon /app

# Switch to non-root user
USER jellydemon

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 jellydemon.py --test || exit 1

# Default command
CMD ["python3", "jellydemon.py"]

# Expose ports (none needed for this daemon)
# EXPOSE 8080

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV JELLYDEMON_CONFIG_FILE=/app/config/config.yml
