#!/bin/bash

# ============================================
# Pterodactyl Full Stack Installer
# ============================================

# Colors
RED='\033[0;31m'
GRN='\033[0;32m'
CYN='\033[0;36m'
YEL='\033[1;33m'
MAG='\033[0;35m'
NC='\033[0m'

clear
echo -e "${MAG}"
cat << "EOF"
╔══════════════════════════════════════════════════╗
║      Pterodactyl Control Panel + Wings           ║
║               Complete Installer                 ║
╚══════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Function to check Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${YEL}Installing Docker...${NC}"
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YEL}Installing Docker Compose...${NC}"
        apt-get update
        apt-get install -y docker-compose
    fi
}

# Function to install Panel
install_panel() {
    echo -e "${CYN}Installing Pterodactyl Panel...${NC}"
    
    mkdir -p /var/lib/pterodactyl-panel
    cd /var/lib/pterodactyl-panel
    
    # Create panel docker-compose
    cat << 'EOF' > docker-compose.yml
version: '3.8'
services:
  panel:
    image: ghcr.io/pterodactyl/panel:latest
    container_name: pterodactyl-panel
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "./data:/app"
    environment:
      APP_URL: http://localhost
      APP_ENV: production
EOF
    
    docker-compose up -d
    echo -e "${GRN}Panel installed! Access at: http://$(curl -s ifconfig.me)${NC}"
}

# Function to install Wings (FIXED)
install_wings() {
    echo -e "${CYN}Installing Pterodactyl Wings...${NC}"
    
    # Clean up
    docker stop wings 2>/dev/null || true
    docker rm wings 2>/dev/null || true
    
    # Create directory
    mkdir -p /etc/pterodactyl
    cd /etc/pterodactyl
    
    # Create wings directory structure
    mkdir -p {data,logs,config}
    
    # Create config file
    cat > config.yml << 'EOF'
# Pterodactyl Wings Configuration
debug: false
panel:
  url: "http://localhost"
  token: "ptla_xxxxxxxxxxxx"
system:
  data: "/var/lib/pterodactyl"
  sftp:
    bind_port: 2022
EOF
    
    # Run wings with correct command
    docker run -d \
        --name wings \
        --restart unless-stopped \
        --network host \
        --privileged \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /etc/pterodactyl/config.yml:/etc/pterodactyl/config.yml \
        -v /var/lib/pterodactyl:/var/lib/pterodactyl \
        ghcr.io/pterodactyl/wings:latest
    
    echo -e "${GRN}Wings installed!${NC}"
    echo -e "${YEL}IMPORTANT: Edit /etc/pterodactyl/config.yml with your panel token${NC}"
}

# Main menu
echo -e "${CYN}Select installation type:${NC}"
echo "1) Install Panel only"
echo "2) Install Wings only"
echo "3) Install Panel + Wings"
echo "4) Exit"
echo -n "Your choice [1-4]: "
read choice

case $choice in
    1)
        check_docker
        install_panel
        ;;
    2)
        check_docker
        install_wings
        ;;
    3)
        check_docker
        install_panel
        sleep 10
        install_wings
        ;;
    4)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

# Post-install info
echo -e "\n${GRN}════════════════════════════════════════${NC}"
echo -e "${GRN}Installation Complete!${NC}"
echo -e "${GRN}════════════════════════════════════════${NC}"
echo -e "\n${CYN}Quick Commands:${NC}"
echo "Panel logs: docker-compose -f /var/lib/pterodactyl-panel/docker-compose.yml logs"
echo "Wings logs: docker logs -f wings"
echo "Restart wings: docker restart wings"
echo "Check status: docker ps"
