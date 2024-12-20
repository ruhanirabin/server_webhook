#!/bin/bash
#
# Author: Ruhani Rabin https://www.ruhanirabin.com
#
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

# If no arguments are provided, show an error and help
if [ $# -eq 0 ]; then
  echo "Error: No arguments provided."
  echo "Usage: ./webhook.sh -e \"My custom message\" https://somelink"
  echo "For more options, run: ./webhook.sh -h"
  exit 1
fi

# Function to send webhook
send_webhook() {
  local url="$1"
  local text="$2"
  local payload='{
    "date": "'"$human_readable_date"'",
    "host_ip": "'"$ip_address"'",
    "host_name": "'"$hostname"'",
    "text": "'"$text"'"
  }'

  http_status=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "$payload" "$url")

  if [[ "$http_status" -ne 200 ]]; then
    echo "Failed to send webhook notification. HTTP Status: $http_status"
    exit 1
  fi

  echo "Webhook notification sent successfully!"
}

# Default variables (will be overridden if -e is used)
additional_text=""
webhooks_url=""

# Parse arguments
INSTALL_MODE=false
UNINSTALL_MODE=false
TEST_MODE=false
EXEC_MODE=false
CUSTOM_TEXT_MODE=false

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -i)
      # Install mode
      INSTALL_MODE=true
      shift # past -i
      ;;
    -u)
      # Uninstall mode
      UNINSTALL_MODE=true
      shift # past -u
      ;;
    -t)
      # Test mode
      TEST_MODE=true
      shift # past -t
      webhooks_url="$1"
      if [ -z "$webhooks_url" ]; then
        echo "Error: Webhook URL is required with -t."
        exit 1
      fi
      shift # past the webhook URL
      additional_text="Test message"
      ;;
    -e)
      # Custom text mode
      CUSTOM_TEXT_MODE=true
      shift # past -e
      additional_text="$1"
      if [ -z "$additional_text" ]; then
        echo "Error: Additional text value is required with -e."
        exit 1
      fi
      shift # past the additional text

      webhooks_url="$1"
      if [ -z "$webhooks_url" ]; then
        echo "Error: Webhook URL is required after the additional text."
        exit 1
      fi
      shift # past the webhook URL
      ;;
    -h|--help)
      # Display help message
      echo "Webhook Installer"
      echo ""
      echo "Usage:"
      echo "  ./webhook.sh -i -e \"<text>\" <webhook_url>     Install service and set it to send the specified text to the specified URL when triggered"
      echo "  ./webhook.sh -u                                Uninstall webhook script and systemd service"
      echo "  ./webhook.sh -t <webhook_url>                  Test sending a webhook to the specified URL with a test message"
      echo "  ./webhook.sh -e \"<text>\" <webhook_url>        Send a webhook once with the specified text and URL"
      echo "  ./webhook.sh -h, --help                        Display this help message"
      echo ""
      echo "Recommended Usage:"
      echo "  ./webhook.sh -e \"My custom message\" https://somelink"
      echo "  ./webhook.sh -i -e \"Machine Restarting now\" https://webhookcall.com"
      exit 0
      ;;
    *)
      # Unknown option
      echo "Error: Invalid option '$1'."
      echo "Usage: ./webhook.sh -h for help."
      exit 1
      ;;
  esac
done

# Execute based on the chosen mode
if [ "$INSTALL_MODE" = true ]; then
  # When installing, we expect -e option with text and URL
  if [ "$CUSTOM_TEXT_MODE" != true ]; then
    echo "Error: You must use -e \"<text>\" <webhook_url> with -i to install."
    echo "Example: ./webhook.sh -i -e \"Machine Restarting now\" https://webhookcall.com"
    exit 1
  fi

  echo "Installing script and systemd service..."

  # Install webhook script to a known location
  cp "$(basename "$0")" /usr/local/bin/webhook.sh
  chmod +x /usr/local/bin/webhook.sh

  # Create systemd service file dynamically
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

  systemctl daemon-reload
  systemctl enable webhook.service
  sudo systemctl start webhook.service

  echo "Script and service installed successfully!"
  echo "When triggered, this service will send: \"$additional_text\" to $webhooks_url"
  exit 0

fi

if [ "$UNINSTALL_MODE" = true ]; then
  echo "Uninstalling script and systemd service..."
  systemctl stop webhook.service || true
  systemctl disable webhook.service || true
  rm -f /etc/systemd/system/webhook.service
  rm -f /usr/local/bin/webhook.sh
  systemctl daemon-reload
  echo "Script and service uninstalled successfully!"
  exit 0
fi

if [ "$TEST_MODE" = true ]; then
  # Test sending a webhook to the specified URL with a test message
  echo "Testing script..."
  send_webhook "$webhooks_url" "$additional_text"
  exit 0
fi

if [ "$CUSTOM_TEXT_MODE" = true ]; then
  # Send one-time webhook with provided text and URL
  echo "Sending webhook with custom additional text..."
  send_webhook "$webhooks_url" "$additional_text"
  exit 0
fi

# If we reach here, it means no valid mode was triggered
echo "Error: No valid option was provided."
echo "Usage: ./webhook.sh -h for help."
exit 1

