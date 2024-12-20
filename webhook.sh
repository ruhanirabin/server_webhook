#!/bin/bash
#
# Author: Ruhani Rabin https://www.ruhanirabin.com
# Revision: 3.2
# This file is part of Webhook Script.
#
# Webhook Script is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Webhook Script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Webhook Script. If not, see <https://www.gnu.org/licenses/>.

# Exit immediately if a command exits with a non-zero status
set -e

# Check compatibility
if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This script is designed for Linux systems only."
  exit 1
fi

# Get current date and time
human_readable_date=$(date +"%Y-%m-%d %H:%M:%S")

# Get hostname
hostname=$(hostname)

# Get public IP address using an external service
ip_address=$(curl -s https://ifconfig.me)

# Function to send webhook
send_webhook() {
  local url="$1"
  local text="$2"
  local payload='{
    "date": "'$human_readable_date'",
    "host_ip": "'$ip_address'",
    "host_name": "'$hostname'",
    "text": "'$text'"
  }'

  http_status=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "$payload" "$url")

  if [[ "$http_status" -ne 200 ]]; then
    echo "Failed to send webhook notification. HTTP Status: $http_status"
    exit 1
  fi

  echo "Webhook notification sent successfully!"
}

# Check if service is already installed
check_installed_service() {
  if [ -f /etc/systemd/system/webhook.service ]; then
    echo "Webhook service is already installed."
    echo "Stopping service for update..."
    sudo systemctl stop webhook.service

    echo "Updating script to the latest version..."
    cp "$(basename "$0")" /usr/local/bin/webhook.sh
    chmod +x /usr/local/bin/webhook.sh

    echo "Re-enabling and restarting service..."
    sudo systemctl daemon-reload
    sudo systemctl enable webhook.service
    sudo systemctl start webhook.service

    echo "Service updated and restarted successfully."
    exit 0
  fi
}

# Default variables
additional_text=""
webhooks_url=""
INSTALL_MODE=false
UNINSTALL_MODE=false
CUSTOM_TEXT_MODE=false

if [ $# -eq 0 ]; then
  read -p "Enter custom text message: " additional_text
  if [ -z "$additional_text" ]; then
    echo "Error: Custom text message cannot be empty."
    exit 1
  fi

  read -p "Enter the webhook URL: " webhooks_url
  if [ -z "$webhooks_url" ]; then
    echo "Error: Webhook URL cannot be empty."
    exit 1
  fi

  send_webhook "$webhooks_url" "$additional_text"
  exit 0
fi

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -i)
      INSTALL_MODE=true
      shift
      ;;
    -u)
      UNINSTALL_MODE=true
      shift
      ;;
    -e)
      CUSTOM_TEXT_MODE=true
      shift
      additional_text="$1"
      if [ -z "$additional_text" ]; then
        echo "Error: Additional text value is required with -e."
        exit 1
      fi
      shift
      webhooks_url="$1"
      if [ -z "$webhooks_url" ]; then
        echo "Error: Webhook URL is required after the additional text."
        exit 1
      fi
      shift
      ;;
    -h|--help)
      echo "Webhook Installer"
      echo ""
      echo "Usage:"
      echo "  ./webhook.sh -i -e \"<text>\" <webhook_url>     Install service and set it to send the specified text to the specified URL when triggered"
      echo "  ./webhook.sh -u                                Uninstall webhook script and systemd service"
      echo "  ./webhook.sh -e \"<text>\" <webhook_url>        Send a webhook once with the specified text and URL"
      echo "  ./webhook.sh (no arguments)                    Prompt interactively for text and URL, then send webhook"
      echo "  ./webhook.sh -h, --help                        Display this help message"
      exit 0
      ;;
    *)
      echo "Error: Invalid option '$1'."
      echo "Usage: ./webhook.sh -h for help."
      exit 1
      ;;
  esac
done

if [ "$INSTALL_MODE" = true ]; then
  check_installed_service
  
  if [ "$CUSTOM_TEXT_MODE" != true ]; then
    echo "Error: You must use -e \"<text>\" <webhook_url> with -i to install."
    exit 1
  fi

  echo "Installing script and systemd service..."
  cp "$(basename "$0")" /usr/local/bin/webhook.sh
  chmod +x /usr/local/bin/webhook.sh

  SERVICE_FILE="/etc/systemd/system/webhook.service"
  cat <<EOF | sudo tee "$SERVICE_FILE"
[Unit]
Description=Send custom webhook on system event
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/webhook.sh -e "$additional_text" $webhooks_url

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable webhook.service
  sudo systemctl start webhook.service

  echo "Script and service installed successfully!"
  echo "When triggered, this service will send: \"$additional_text\" to $webhooks_url"
  exit 0
fi

if [ "$UNINSTALL_MODE" = true ]; then
  echo "Uninstalling script and systemd service..."
  sudo systemctl stop webhook.service || true
  sudo systemctl disable webhook.service || true
  rm -f /etc/systemd/system/webhook.service
  rm -f /usr/local/bin/webhook.sh
  sudo systemctl daemon-reload
  echo "Script and service uninstalled successfully!"
  exit 0
fi

if [ "$CUSTOM_TEXT_MODE" = true ]; then
  send_webhook "$webhooks_url" "$additional_text"
  exit 0
fi

# If no valid mode
echo "Error: No valid option provided."
echo "Usage: ./webhook.sh -h for help."
exit 1