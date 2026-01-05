#!/bin/bash

# ============================================
# Pterodactyl Wings Installer (Fixed Version)
# ============================================

# Colors
RED='\033[0;31m'
GRN='\033[0;32m'
CYN='\033[0;36m'
YEL='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${CYN}Installing Pterodactyl Wings...${NC}"

# 1. Clean up existing containers (IMPORTANT)
echo -e "${YEL}Cleaning up existing containers...${NC}"
docker-compose down --remove-orphans 2>/dev/null || true
docker rm -f wings 2>/dev/null || true

# 2. Create directory structure
echo -e "${YEL}Creating directories...${NC}"
mkdir -p /etc/pterodactyl/{data,logs,ssl}
cd /etc/pterodactyl || exit

# 3. Create fixed docker-compose.yml
echo -e "${YEL}Creating docker-compose.yml...${NC}"
cat << 'EOF' > docker-compose.yml
version: '3.8'

services:
  wings:
    image: ghcr.io/pterodactyl/wings:latest
    container_name: wings
    restart: unless-stopped
    network_mode: host
    privileged: true
    user: root
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./config.yml:/etc/pterodactyl/config.yml:ro
      - ./data:/var/lib/pterodactyl
      - ./logs:/var/log/pterodactyl
      - ./ssl:/etc/ssl/certs
      - /etc/letsencrypt:/etc/letsencrypt:ro
      - /tmp:/tmp
    environment:
      TZ: UTC
    command: ["/usr/local/bin/wings", "--debug"]
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOF

# 4. Create minimal config.yml
echo -e "${YEL}Creating config.yml...${NC}"
cat << 'EOF' > config.yml
---
debug: true
panel:
  url: "https://your-panel-url.com"
  token: "CHANGE_ME"
  timeout: 30
system:
  data: /var/lib/pterodactyl
  sftp:
    bind_port: 2022
docker:
  network:
    name: "pterodactyl_nw"
    interface: "eth0"
EOF

# 5. Pull the image first
echo -e "${YEL}Pulling wings image...${NC}"
docker pull ghcr.io/pterodactyl/wings:latest

# 6. Create network if doesn't exist
echo -e "${YEL}Creating Docker network...${NC}"
docker network create pterodactyl_nw 2>/dev/null || true

# 7. Start without --force-recreate first
echo -e "${YEL}Starting wings container...${NC}"
docker-compose up -d

# Wait a moment
sleep 5

# 8. Check if container is running
if docker ps | grep -q wings; then
    echo -e "${GRN}✓ Wings container started successfully!${NC}"
    
    # 9. Now force recreate if needed
    echo -e "${YEL}Force recreating to ensure clean state...${NC}"
    docker-compose up -d --force-recreate
    
    echo -e "\n${GRN}========================================${NC}"
    echo -e "${GRN}Installation completed!${NC}"
    echo -e "========================================${NC}"
    
    # Show container info
    echo -e "\n${CYN}Container status:${NC}"
    docker-compose ps
    
    echo -e "\n${CYN}Logs (last 10 lines):${NC}"
    docker-compose logs --tail=10 wings
    
else
    echo -e "${RED}Failed to start container. Trying alternative method...${NC}"
    
    # Alternative: Run directly with docker run
    docker run -d \
        --name wings \
        --restart unless-stopped \
        --network host \
        --privileged \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /etc/pterodactyl/config.yml:/etc/pterodactyl/config.yml:ro \
        -v /etc/pterodactyl/data:/var/lib/pterodactyl \
        -v /etc/pterodactyl/logs:/var/log/pterodactyl \
        -v /etc/pterodactyl/ssl:/etc/ssl/certs \
        -v /etc/letsencrypt:/etc/letsencrypt:ro \
        -v /tmp:/tmp \
        -e TZ=UTC \
        ghcr.io/pterodactyl/wings:latest \
        /usr/local/bin/wings --debug
    
    echo -e "${YEL}Container started with docker run command${NC}"
fi

# 10. Post-install instructions
echo -e "\n${YEL}IMPORTANT NEXT STEPS:${NC}"
echo -e "1. Edit /etc/pterodactyl/config.yml:"
echo -e "   - Set panel.url to your panel URL"
echo -e "   - Get token from Panel: Settings -> Nodes -> Configuration"
echo -e "2. Restart wings: docker-compose restart"
echo -e "3. Check logs: docker-compose logs -f wings"
echo -e "\n${CYN}Useful commands:${NC}"
echo -e "  View logs: docker-compose logs -f"
echo -e "  Restart:   docker-compose restart"
echo -e "  Stop:      docker-compose down"
echo -e "  Status:    docker-compose ps"

# Quick fix command
echo -e "\n${GRN}If you still have issues, run this command:${NC}"
echo -e "cd /etc/pterodactyl && docker-compose down && docker-compose up -d --build"
