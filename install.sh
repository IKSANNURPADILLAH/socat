#!/bin/bash

# ===== CONFIGURATION =====
LISTEN_PORT=443
POOL_HOST="prlx.coolpool.top"
POOL_PORT=3003
SERVICE_NAME="prlx-socat-mining"

# ===== INSTALL SOCAT =====
echo "[+] Installing socat..."
sudo apt update -y
sudo apt install socat -y

# ===== CREATE SYSTEMD SERVICE =====
echo "[+] Creating systemd service..."
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Socat TCP Forwarding for Mining
After=network.target

[Service]
ExecStart=/usr/bin/socat TCP-LISTEN:${LISTEN_PORT},reuseaddr,fork TCP:${POOL_HOST}:${POOL_PORT}
Restart=always
RestartSec=5
LimitNOFILE=100000
User=root

[Install]
WantedBy=multi-user.target
EOF

# ===== SYSTEM LIMITS =====
echo "[+] Setting nofile limits..."
sudo bash -c 'echo "* soft nofile 100000" >> /etc/security/limits.conf'
sudo bash -c 'echo "* hard nofile 100000" >> /etc/security/limits.conf'
sudo bash -c 'echo "session required pam_limits.so" >> /etc/pam.d/common-session'
sudo bash -c 'echo "session required pam_limits.so" >> /etc/pam.d/common-session-noninteractive'

# ===== SYSCTL TUNING =====
echo "[+] Applying sysctl tuning..."
sudo bash -c 'echo "fs.file-max = 200000" >> /etc/sysctl.conf'
sudo bash -c 'echo "net.core.somaxconn = 65535" >> /etc/sysctl.conf'
sudo sysctl -p

# ===== ENABLE & START SERVICE =====
echo "[+] Enabling and starting service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now ${SERVICE_NAME}

echo "[✓] Service '${SERVICE_NAME}' is now running and will auto-restart if it dies."
echo "Listening on port ${LISTEN_PORT} -> Forwarded to ${POOL_HOST}:${POOL_PORT}"
