#!/bin/bash

# Define paths
SCRIPT_PATH="/usr/local/bin/notify_ssh.sh"
SERVICE_PATH="/etc/systemd/system/notify-ssh.service"
PAM_SSHD="/etc/pam.d/sshd"

# Create notify script
cat <<EOF > $SCRIPT_PATH
#!/bin/bash

NTFY_URL="https://ntfy.luishomeserver.com/homeserver-access"
HOSTNAME=\$(hostname)
TIMESTAMP=\$(date +"%Y-%m-%d %H:%M:%S")
USER_NAME=\$(whoami)
IP_ADDRESS=\$(echo \$SSH_CONNECTION | awk '{print \$1}')
PUBLIC_IP=\$(curl -s https://ifconfig.me)  # Fetch public IP
TTY=\$(tty)

# Ensure the script only sends notifications on login, not logout
if [[ \$(who | grep "\$USER_NAME" | grep "\$TTY") ]]; then
    curl -X POST "\$NTFY_URL" \
         -H "Title: 🚀 SSH Login Detected" \
         -H "Priority: high" \
         -H "Tags: lock,computer" \
         -H "Content-Type: text/plain" \
         -d "🔐 *New SSH Access*
- **User:** \$USER_NAME
- **Local IP:** \$IP_ADDRESS
- **Public IP:** \$PUBLIC_IP
- **Host:** \$HOSTNAME
- **TTY:** \$TTY
- **Time:** \$TIMESTAMP"
fi
EOF

# Make script executable
chmod +x $SCRIPT_PATH

# Create systemd service
cat <<EOF > $SERVICE_PATH
[Unit]
Description=Notify SSH Login via ntfy.sh
After=network.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable notify-ssh.service

# Append PAM rule to trigger the script on SSH login
if ! grep -q "pam_exec.so $SCRIPT_PATH" "$PAM_SSHD"; then
    echo "session optional pam_exec.so $SCRIPT_PATH" >> "$PAM_SSHD"
fi

echo "Installation complete. SSH notifications with public IP detection are now enabled."
