#!/bin/bash

# CodeSandbox-specific Pterodactyl Wings Installer
echo "Installing Pterodactyl Wings for CodeSandbox..."

# Create directories in user space (no permissions needed)
mkdir -p ~/pterodactyl/{config,data,logs,certs}

# Create minimal docker-compose in home directory
cd ~/pterodactyl

cat << 'EOF' > docker-compose.yml
version: '3.8'

services:
  wings:
    image: ghcr.io/pterodactyl/wings:latest
    container_name: pterodactyl-wings
    restart: unless-stopped
    network_mode: host
    user: "1000:1000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./config/config.yml:/etc/pterodactyl/config.yml
      - ./data:/var/lib/pterodactyl
      - ./logs:/var/log/pterodactyl
      - ./certs:/etc/ssl/certs
    environment:
      TZ: UTC
      WINGS_DEBUG: "true"
EOF

# Create config file
cat << 'EOF' > config/config.yml
# Pterodactyl Wings Configuration for CodeSandbox
debug: true

panel:
  url: "http://localhost:8000"  # Change this to your panel URL
  token: "ptla_xxxxxxxxxxxx"     # Get from panel
  timeout: 30

system:
  data: "/var/lib/pterodactyl"
  sftp:
    bind_port: 2022
    bind_address: "0.0.0.0"

docker:
  network:
    name: "pterodactyl-network"
    interface: "eth0"

allowed_mounts: []
remote: "http://localhost:8000"
EOF

# Pull the image
docker pull ghcr.io/pterodactyl/wings:latest

# Start the container
docker-compose up -d

echo ""
echo "========================================="
echo "Installation Complete!"
echo "========================================="
echo ""
echo "Important:"
echo "1. Edit ~/pterodactyl/config/config.yml"
echo "2. Set your panel URL and token"
echo "3. Restart: docker-compose restart"
echo ""
echo "Config location: ~/pterodactyl/config/config.yml"
echo "Data location: ~/pterodactyl/data"
echo "Logs location: ~/pterodactyl/logs"
echo ""
echo "Check status: docker-compose ps"
echo "View logs: docker-compose logs -f"
