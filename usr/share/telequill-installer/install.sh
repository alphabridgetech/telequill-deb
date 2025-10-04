#!/bin/bash
set -e

WELCOME_FILE="/usr/share/telequill-installer/welcome.txt"
GUIDE_FILE="/usr/share/telequill-installer/userguide.txt"
LICENSE_FILE="/usr/share/telequill-installer/license.txt"

whiptail --title "Telequill NMS" --msgbox "$(cat $WELCOME_FILE)" 20 70
whiptail --title "User Guide" --msgbox "$(cat $GUIDE_FILE)" 20 70
whiptail --title "License Agreement" --yesno "$(cat $LICENSE_FILE)" 25 70
[ $? -eq 0 ] || { echo "License not accepted. Aborting."; exit 1; }

step(){ echo -e "\n\033[1;32m==> $1\033[0m"; }

if ! command -v docker >/dev/null 2>&1; then
    step "Docker not found. Installing Docker..."
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl python3 git
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo ${UBUNTU_CODENAME:-$VERSION_CODENAME}) stable" \
      | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    step "Docker already installed. Updating packages..."
    sudo apt-get update -y
fi

if [ -d "/opt/Telequill_Install/.git" ]; then
    step "Pulling latest changes in /opt/Telequill_Install"
    sudo git -C /opt/Telequill_Install pull --rebase
else
    step "Cloning Telequill_Install repository"
    sudo rm -rf /opt/Telequill_Install
    sudo git clone https://github.com/alphabridgetech/Telequill_Install.git /opt/Telequill_Install
fi

step "Building Docker image my-librenms"
cd /opt/Telequill_Install
sudo docker build -t my-librenms .

step "Starting containers with docker compose"
cd /opt/Telequill_Install/examples/compose
sudo docker compose -f compose.yml up -d

whiptail --title "Telequill NMS" --msgbox "🎉 Installation and deployment complete." 12 60
