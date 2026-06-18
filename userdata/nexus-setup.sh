#!/bin/bash

set -euo pipefail

# Variables
NEXUS_VERSION="3.78.0-14"
NEXUS_URL="https://download.sonatype.com/nexus/3/nexus-unix-x86-64-${NEXUS_VERSION}.tar.gz"
INSTALL_DIR="/opt/nexus"
DATA_DIR="/opt/sonatype-work"
TMP_DIR="/tmp/nexus-install"

echo "Installing Java 17 and required packages..."
sudo dnf update -y
sudo dnf install -y java-17-amazon-corretto-devel wget tar

echo "Verifying Java installation..."
java -version

echo "Creating Nexus user..."
if ! id nexus &>/dev/null; then
    sudo useradd --system --create-home nexus
fi

echo "Preparing directories..."
sudo mkdir -p "${INSTALL_DIR}"
sudo mkdir -p "${DATA_DIR}"
mkdir -p "${TMP_DIR}"

cd "${TMP_DIR}"

echo "Downloading Nexus ${NEXUS_VERSION}..."
wget -O nexus.tar.gz "${NEXUS_URL}"

echo "Extracting Nexus..."
NEXUS_DIR=$(tar -tzf nexus.tar.gz | head -1 | cut -d'/' -f1)
tar -xzf nexus.tar.gz

echo "Installing Nexus..."
sudo rm -rf "${INSTALL_DIR:?}/${NEXUS_DIR}"
sudo mv "${NEXUS_DIR}" "${INSTALL_DIR}/"

echo "Setting permissions..."
sudo chown -R nexus:nexus "${INSTALL_DIR}"
sudo chown -R nexus:nexus "${DATA_DIR}"

echo "Configuring Nexus to run as nexus user..."
echo 'run_as_user="nexus"' | sudo tee "${INSTALL_DIR}/${NEXUS_DIR}/bin/nexus.rc" >/dev/null

echo "Creating systemd service..."

sudo tee /etc/systemd/system/nexus.service >/dev/null <<EOF
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=nexus
Group=nexus
ExecStart=${INSTALL_DIR}/${NEXUS_DIR}/bin/nexus start
ExecStop=${INSTALL_DIR}/${NEXUS_DIR}/bin/nexus stop
Restart=on-failure
TimeoutStartSec=600
TimeoutStopSec=600

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd..."
sudo systemctl daemon-reload

echo "Enabling Nexus service..."
sudo systemctl enable nexus

echo "Starting Nexus..."
sudo systemctl start nexus

echo "Waiting for Nexus startup..."
sleep 30

echo "Nexus service status:"
sudo systemctl --no-pager status nexus

echo ""
echo "Installation completed."
echo "Access Nexus at:"
echo "http://<SERVER-IP>:8081"
echo ""
echo "Initial admin password:"
echo "sudo cat /opt/sonatype-work/nexus3/admin.password"
