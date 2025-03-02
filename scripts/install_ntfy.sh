#!/bin/bash

# Define paths
SCRIPT_PATH="/usr/local/bin/notify_ssh.sh"
SERVICE_PATH="/etc/systemd/system/notify-ssh.service"
PAM_SSHD="/etc/pam.d/sshd"

# Create the notification script
cat <<EOF > $SCRIPT_PATH
#!/bin/bash
NTFY_URL="https://ntfy.luishomeserver.com/homeserver-access"
TOPIC="homeserver-access"

IP_ADDRESS=\$(echo \$SSH_CONNECTION | awk '{print \$1}')
HOSTNAME=\$(hostname)
TIMESTAMP=\$(date +"%Y-%m-%d %H:%M:%S")
USER_NAME=\$(whoami)
TTY=\$(tty)

if [[ \$(who | grep "\$USER_NAME" | grep "\$TTY") ]]; then
    curl -X POST "\$NTFY_URL/\$TOPIC" \
         -H "Title: 🚀 SSH Login Detected" \
         -H "Priority: high" \
         -H "Tags: lock,computer" \
         -H "Content-Type: text/plain" \
         -d "🔐 *New SSH Access*
- **User:** \$USER_NAME
- **From:** \$IP_ADDRESS
- **Host:** \$HOSTNAME
- **TTY:** \$TTY
- **Time:** \$TIMESTAMP"
fi
EOF

# Make script executable
chmod +x $SCRIPT_PATH

# Append PAM rule to trigger the script on SSH login only if not already added
if ! grep -q "pam_exec.so $SCRIPT_PATH" "$PAM_SSHD"; then
    echo "session optional pam_exec.so $SCRIPT_PATH" >> "$PAM_SSHD"
fi

echo "Installation complete. SSH login notifications are now enabled."
