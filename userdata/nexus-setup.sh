#!/bin/bash
set -e

NEXUS_URL="https://download.sonatype.com/nexus/3/nexus-3.93.0-06-linux-x86_64.tar.gz"
TAR_NAME="nexus-3.93.0-06-linux-x86_64.tar.gz"
EXTRACTED_DIR="nexus-3.93.0-06"
INSTALL_DIR="/opt"

echo "===================================================="
echo " Starting Sonatype Nexus Repository Installation"
echo "===================================================="

# 1. System Prep
echo "[1/5] Installing OpenJDK 21 & Wget..."
sudo apt update -y
sudo apt install openjdk-21-jdk wget -y

# 2. Extract application files
echo "[2/5] Downloading and extracting package..."
cd $INSTALL_DIR
# If cleaning up a previous failed installation attempt, uncomment the line below:
# sudo rm -rf nexus sonatype-work
sudo wget -q --show-progress "$NEXUS_URL"
sudo tar -xvzf "$TAR_NAME"
sudo mv "$EXTRACTED_DIR" nexus
sudo rm "$TAR_NAME"

# 3. Handle System User & Permissions
echo "[3/5] Configuring 'nexus' system user accounts..."
if ! id "nexus" &>/dev/null; then
    sudo adduser --disabled-password --gecos "" nexus
fi

# 4. Correctly generate the nexus.rc configurations
echo "[4/5] Writing user constraints into runtime environment config..."
sudo bash -c 'echo "run_as_user=\"nexus\"" > /opt/nexus/bin/nexus.rc'

# Ensure complete user ownership across directories
sudo chown -R nexus:nexus /opt/nexus
sudo chown -R nexus:nexus /opt/sonatype-work

# 5. Create Systemd Service Descriptor
echo "[5/5] Generating systemd unit wrapper..."
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

echo "Reloading configurations and triggering startup..."
sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl restart nexus

echo "===================================================="
echo " Setup complete! Access your console at port :8081"
echo "===================================================="
