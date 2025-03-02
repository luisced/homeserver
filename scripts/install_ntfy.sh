#!/bin/bash

# Define paths
SCRIPT_PATH="/usr/local/bin/notify_ssh.sh"
SERVICE_PATH="/etc/systemd/system/notify-ssh.service"
PAM_SSHD="/etc/pam.d/sshd"

# Create notify script
cat <<'EOF' > $SCRIPT_PATH
#!/bin/bash

# Define ntfy URL
NTFY_URL="https://ntfy.luishomeserver.com/homeserver-access"

# Gather SSH session details
HOSTNAME=$(hostname)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
USER_NAME=$(whoami)
IP_ADDRESS=$(echo $SSH_CONNECTION | awk '{print $1}')
TTY=$(tty)

# Get Public IP
PUBLIC_IP=$(curl -s https://ifconfig.me)  # Alternative: curl -s https://ipinfo.io/ip

# Construct the notification message
MESSAGE="User: $USER_NAME
From: $IP_ADDRESS (Internal)
Public IP: $PUBLIC_IP
Host: $HOSTNAME
TTY: $TTY
Time: $TIMESTAMP"

# Send the notification
curl -X POST "$NTFY_URL" \
    -H "Title: SSH Access Detected" \
    -H "Priority: high" \
    -H "Tags: lock,rocket" \
    -H "Click: ssh://$IP_ADDRESS" \
    -d "$MESSAGE"

EOF

# Make script executable
chmod +x $SCRIPT_PATH

# Create systemd service
cat <<EOF > $SERVICE_PATH
[Unit]
Description=Notify SSH Login via ntfy
After=network.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
User=root
Group=root
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable the service
systemctl daemon-reload
systemctl enable notify-ssh.service

# Append PAM rule to trigger the script on SSH login
if ! grep -q "session optional pam_exec.so $SCRIPT_PATH" "$PAM_SSHD"; then
    echo "session optional pam_exec.so $SCRIPT_PATH" >> "$PAM_SSHD"
fi

echo "Installation complete. SSH notifications are now enabled."
