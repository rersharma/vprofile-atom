#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define variables
NEXUS_URL="https://download.sonatype.com/nexus/3/nexus-3.93.0-06-linux-x86_64.tar.gz"
TAR_NAME="nexus-3.93.0-06-linux-x86_64.tar.gz"
EXTRACTED_DIR="nexus-3.93.0-06"
INSTALL_DIR="/opt"

echo "===================================================="
echo " Starting Sonatype Nexus Repository Installation"
echo "===================================================="

# 1. Update system and install Java (OpenJDK 21)
echo "[1/6] Updating system and installing OpenJDK 21..."
sudo apt update -y
sudo apt install openjdk-21-jdk wget -y

# 2. Download and extract Nexus
echo "[2/6] Downloading and extracting Nexus package..."
cd $INSTALL_DIR
sudo wget -q --show-progress "$NEXUS_URL"
sudo tar -xvzf "$TAR_NAME"

# Rename extracted folder to a generic name and clean up the archive
sudo mv "$EXTRACTED_DIR" nexus
sudo rm "$TAR_NAME"

# 3. Create a dedicated system user
echo "[3/6] Creating dedicated 'nexus' system user..."
if ! id "nexus" &>/dev/null; then
    sudo adduser --disabled-password --gecos "" nexus
else
    echo "User 'nexus' already exists, skipping creation."
fi

# Set proper ownership permissions
sudo chown -R nexus:nexus /opt/nexus
sudo chown -R nexus:nexus /opt/sonatype-work

# 4. Configure Nexus to run as the 'nexus' user
echo "[4/6] Configuring Nexus application runner user..."
sudo sed -i 's/#run_as_user=""/run_as_user="nexus"/' /opt/nexus/bin/nexus.rc

# 5. Create Systemd Service
echo "[5/6] Generating systemd service unit configuration..."
sudo bash -c 'cat > /etc/systemd/system/nexus.service <<EOF
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF'

# 6. Reload daemon and launch service
echo "[6/6] Reloading systemd daemons and starting Nexus..."
sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus

echo "===================================================="
echo " Nexus Installation Completed Successfully!"
echo "===================================================="
echo "Please wait a minute or two for the web app to fully initialize."
echo "You can access the console at: http://YOUR_SERVER_IP:8081"
echo "Fetch your initial temporary admin password using:"
echo "sudo cat /opt/sonatype-work/nexus3/admin.password"
echo "===================================================="
