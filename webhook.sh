#!/bin/bash

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

# Set default values (can be overridden by parameters)
additional_text="Default text message"
webhooks_url="https://somelink"

# Function to send webhook
send_webhook() {
  local url="$1"
  local payload='{
    "date": "'"$human_readable_date"'",
    "host_ip": "'"$ip_address"'",
    "host_name": "'"$hostname"'",
    "text": "'"$additional_text"'"
  }'

  http_status=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "$payload" "$url")

  if [[ "$http_status" -ne 200 ]]; then
    echo "Failed to send webhook notification. HTTP Status: $http_status"
    exit 1
  fi

  echo "Webhook notification sent successfully!"
}

# Handle command-line arguments
case "$1" in
  -i)
    # Install script and systemd service
    echo "Installing script..."
    curl -fO https://raw.githubusercontent.com/your-repo/webhook-installers/master/webhook.sh
    chmod +x webhook.sh

    echo "Installing systemd service..."
    cp webhook.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable webhook.service
    systemctl start webhook.service

    echo "Script and service installed successfully!"
    ;;
  -u)
    # Uninstall script and systemd service
    echo "Uninstalling script and systemd service..."
    systemctl stop webhook.service
    systemctl disable webhook.service
    rm /etc/systemd/system/webhook.service
    rm -f webhook.sh

    echo "Script and service uninstalled successfully!"
    ;;
  -t)
    # Test script with specified webhook URL
    if [ -z "$2" ]; then
      echo "Error: Webhook URL is required with -t."
      exit 1
    fi

    webhooks_url="$2"

    echo "Testing script..."
    send_webhook "$webhooks_url"
    ;;
  -e)
    # Set additional text and use default webhook URL (https://somelink)
    if [ -z "$2" ]; then
      echo "Error: Additional text value is required with -e."
      exit 1
    fi
    
    additional_text="$2"
    echo "Sending webhook with custom additional text..."
    send_webhook "$webhooks_url"
    ;;
  -h|--help)
    # Display help message
    echo "Webhook Installer"
    echo ""
    echo "Usage: webhook.sh [-i] [-u] [-t <webhook_url>] [-e <additional_text>] [-h]"
    echo "  -i               Install webhook script and systemd service"
    echo "  -u               Uninstall webhook script and systemd service"
    echo "  -t <webhook_url> Test sending a webhook to the specified URL"
    echo "  -e <text>        Send a webhook with the specified additional text (uses default URL: https://somelink)"
    echo "  -h, --help       Display this help message"
    exit 0
    ;;
  *)
    # Send HTTP POST request to the default webhook URL with default or previously set additional text
    send_webhook "$webhooks_url"
    ;;
esac
