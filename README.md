# Server Restart Webhook Script

## Description

The Webhook Script is a Bash utility designed to send webhook notifications with custom messages and URLs. It supports installation as a systemd service, making it suitable for automation tasks such as system events and scheduled notifications.

*I use this to get notification on my phone when server restarts after a security update via automation tools like pabbly or flowmattic.*

### Key Features

- **Interactive Mode**: Prompts for custom message and URL if run without parameters, and installs as a service.
- **Service Management**: Install and uninstall as a systemd service.
- **Update Handling**: Checks for existing service and updates it if already installed.
- **Custom Notifications**: Send a one-time webhook message with a simple command.
- **Error Handling**: Provides detailed feedback for invalid inputs or issues during execution.

---

## Usage Instructions

Single command latest script execution on SSH terminal, copy the code below and run:

```sudo bash -c "$(curl -fsSL https://github.com/ruhanirabin/server_webhook/raw/main/webhook.sh)"```

This will ask you
- Custom message
- Webhook URL
- Then it will install itself as service

### Prerequisites

- Linux-based operating system.
- Root level permissions.
- `curl` command-line tool installed.

### Running the Script

1. **No Arguments (Interactive Mode)**:
   `./webhook.sh`

    **Prompts for:**
    - A custom text message.
    - A webhook URL.
    - Installs the script as a systemd service.

2. **Install Mode:**

`./webhook.sh -i -e "Custom Message" <webhook_url>`
   - Installs the script and sets it as a systemd service.
   - The specified custom message and URL will be used for notifications.

3. **Uninstall Mode:**

`./webhook.sh -u`
   - Uninstalls the script and removes the systemd service.

4. **Send a One-Time Notification:**

`./webhook.sh -e "One-time Message" <webhook_url>`

   - Sends a single webhook notification with the provided message and URL.

5. Help:

`./webhook.sh -h`
   - Displays usage instructions.

## Systemd Service Behavior
When installed as a service:

- The script will send a webhook notification with the configured message and URL whenever triggered.
- The service is enabled to run on specific system events, such as reboots.

**Intended Use**
This script is designed to automate webhook notifications for Linux systems. Typical use cases include:

- Monitoring system events (e.g., reboots, updates).
- Sending notifications for scheduled tasks.
- Integration with external systems via webhooks.

### License
This script is licensed under the GNU General Public License v3.0.

### Author
Ruhani Rabin
https://www.ruhanirabin.com