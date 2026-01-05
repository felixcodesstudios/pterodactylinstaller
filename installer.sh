#!/bin/bash

# Wings only installer
echo "Installing Pterodactyl Wings with Docker..."

# Update system
apt-get update
apt-get install -y curl docker.io docker-compose

# Create directory
mkdir -p /etc/pterodactyl
cd /etc/pterodactyl || exit

# Create docker-compose for wings
cat << 'EOF' > docker-compose.yml
version: '3.8'

services:
  wings:
    image: ghcr.io/pterodactyl/wings:latest
    container_name: wings
    restart: unless-stopped
    network_mode: host
    user: root
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./config.yml:/etc/pterodactyl/config.yml
      - ./data:/var/lib/pterodactyl
      - ./logs:/var/log/pterodactyl
      - ./ssl:/etc/ssl/certs
      - /etc/letsencrypt:/etc/letsencrypt:ro
    environment:
      TZ: "UTC"
    command: wings --debug
EOF

# Create directories
mkdir -p {data,logs,ssl}

# Create initial config
cat << 'EOF' > config.yml
---
debug: false
panel:
  url: "https://your-panel-url.com"
  token: "your_panel_token_here"
  timeout: 30
docker:
  network:
    name: "pterodactyl_nw"
    interface: "eth0"
  domain: "example.com"
  stats:
    enabled: true
    port: 8085
system:
  root_directory: "/var/lib/pterodactyl/volumes"
  data: "/var/lib/pterodactyl"
  archive_directory: "/var/lib/pterodactyl/archives"
  backup_directory: "/var/lib/pterodactyl/backups"
  sftp:
    bind_address: "0.0.0.0"
    bind_port: 2022
EOF

echo "Starting Wings..."
docker-compose up -d

echo "Installation complete!"
echo "IMPORTANT: Edit /etc/pterodactyl/config.yml with your Panel details"
echo "Get token from Panel Admin -> Nodes -> Configuration"
echo ""
echo "To restart: docker-compose restart"
echo "To view logs: docker-compose logs -f wings"
