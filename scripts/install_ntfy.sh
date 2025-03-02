#!/bin/bash

# Define paths
SCRIPT_PATH="/usr/local/bin/notify_ssh.sh"
SERVICE_PATH="/etc/systemd/system/notify-ssh.service"
PAM_SSHD="/etc/pam.d/sshd"
ENV_FILE="/etc/notify_ssh/.env.ntfy"

# Create directory for environment file
mkdir -p /etc/notify_ssh
chmod 700 /etc/notify_ssh

# Create .env.ntfy file with default configuration if it doesn't exist
if [ ! -f "$ENV_FILE" ]; then
    cat <<EOF > $ENV_FILE
NTFY_URL="https://ntfy.luishomeserver.com/homeserver-access"
EOF
    chmod 600 $ENV_FILE  # Secure the environment file
fi

# Create notify script
cat <<'EOF' > $SCRIPT_PATH
#!/bin/bash

# Load environment variables from .env.ntfy
set -a
source /etc/notify_ssh/.env.ntfy
set +a

# Ensure NTFY_URL is set
if [ -z "$NTFY_URL" ]; then
    echo "Error: NTFY_URL is not set. Please check your .env.ntfy file."
    exit 1
fi

# Gather SSH session details
HOSTNAME=$(hostname)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
USER_NAME=$(who | awk '{print $1}')
IP_ADDRESS=$(echo $SSH_CONNECTION | awk '{print $1}')
TTY=$(who | awk '{print $2}')

# Construct the notification message
MESSAGE="User: $USER_NAME
From: $IP_ADDRESS
Host: $HOSTNAME
TTY: $TTY
Time: $TIMESTAMP"

# Send the notification
curl -X POST "$NTFY_URL" \
    -H "Title: 🔐SSH Access Detected🚀 \
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
EnvironmentFile=$ENV_FILE
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
echo "Edit $ENV_FILE to configure your ntfy notification settings."
