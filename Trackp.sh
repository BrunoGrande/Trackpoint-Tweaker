#!/bin/bash
# trackp: TrackPoint acceleration adjustment and installer.
#
# Usage when not installed (e.g., from Downloads):
#    sudo ./Trackp.sh
#
# When installed (at /usr/local/bin/trackp), use:
#    sudo trackp <value>       # Update the TrackPoint acceleration value (input 1–10; converted to 0.1–1.0)
#    sudo trackp -help         # Display help message.
#    sudo trackp -uninstall    # Uninstall the trackp script, service, and autocompletion.
#
# On installation, the service file is created with a hardcoded default value of 0.5,
# and a Bash autocompletion snippet is installed to /etc/bash_completion.d/trackp.
#
set -euo pipefail

# Function: Display help message.
show_help() {
    cat << EOF
Usage: sudo trackp [option|<acceleration_value>]

Options:
  -help           Display this help message.
  -uninstall      Remove the installed trackp script, its systemd service, and autocompletion.

Acceleration value:
  Provide an integer from 1 to 10. This value is divided by 10 and used as the TrackPoint
  acceleration (e.g., 6 becomes 0.6).

Bash Autocompletion:
  Once installed, Bash autocompletion is enabled automatically. Type 'trackp' and then press TAB
  to see available options.
EOF
}

# Function: Uninstall trackp.
uninstall_trackp() {
    echo "Uninstalling trackp..."
    SERVICE_NAME="trackp.service"
    SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"
    INSTALLED_PATH="/usr/local/bin/trackp"
    COMPLETION_FILE="/etc/bash_completion.d/trackp"

    if [ -f "$SERVICE_FILE" ]; then
        systemctl stop "$SERVICE_NAME" || true
        systemctl disable "$SERVICE_NAME" || true
        rm -f "$SERVICE_FILE"
        rm -f "/etc/systemd/system/graphical.target.wants/${SERVICE_NAME}" || true
        echo "Removed systemd service file $SERVICE_FILE."
    else
        echo "Service file not found."
    fi

    if [ -f "$INSTALLED_PATH" ]; then
        rm -f "$INSTALLED_PATH"
        echo "Removed installed script at $INSTALLED_PATH."
    else
        echo "Installed script not found."
    fi

    if [ -f "$COMPLETION_FILE" ]; then
        rm -f "$COMPLETION_FILE"
        echo "Removed Bash autocompletion file at $COMPLETION_FILE."
    else
        echo "Bash autocompletion file not found."
    fi

    systemctl daemon-reload
    echo "Uninstallation complete."
    exit 0
}

# Ensure the script is run as root.
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

# Process command-line options for help and uninstall.
if [ "$#" -ge 1 ]; then
    case "$1" in
        -help)
            show_help
            exit 0
            ;;
        -uninstall)
            uninstall_trackp
            ;;
    esac
fi

# Define installed path and service file path.
INSTALLED_PATH="/usr/local/bin/trackp"
SERVICE_NAME="trackp.service"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"
CURRENT_PATH=$(realpath "$0")
COMPLETION_FILE="/etc/bash_completion.d/trackp"

# Installation mode: if the script is not running from the installed location.
if [ "$CURRENT_PATH" != "$INSTALLED_PATH" ]; then
    echo "Detected that the script is running from a non-installed location."
    echo "Proceeding with installation..."

    # Copy the script to the installed location.
    if [ -f "$INSTALLED_PATH" ]; then
        if cmp -s "$CURRENT_PATH" "$INSTALLED_PATH"; then
            echo "trackp script already installed and up-to-date. Skipping copy."
        else
            cp "$INSTALLED_PATH" "${INSTALLED_PATH}.bak_$(date +%F_%H%M%S)"
            echo "Backup of existing trackp created."
            cp "$CURRENT_PATH" "$INSTALLED_PATH"
            chmod +x "$INSTALLED_PATH"
            echo "Updated trackp script at $INSTALLED_PATH."
        fi
    else
        cp "$CURRENT_PATH" "$INSTALLED_PATH"
        chmod +x "$INSTALLED_PATH"
        echo "Installed trackp script to $INSTALLED_PATH."
    fi

    # Remove any existing service file.
    if [ -f "$SERVICE_FILE" ]; then
        echo "Systemd service file $SERVICE_FILE already exists, removing it."
        rm -f "$SERVICE_FILE"
    fi

    # Create a new systemd service file with hardcoded default acceleration (0.5).
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=TrackPoint Acceleration Service
After=graphical.target

[Service]
Type=oneshot
Environment="DISPLAY=:0"
Environment="XAUTHORITY=/home/vex/.Xauthority"
ExecStart=/usr/bin/xinput set-prop "pointer:TPPS/2 IBM TrackPoint" "libinput Accel Speed" 0.5
RemainAfterExit=true

[Install]
WantedBy=graphical.target
EOF
    echo "Created systemd service file at $SERVICE_FILE."

    # Install Bash autocompletion snippet.
    cat > "$COMPLETION_FILE" << 'EOF'
_trackp_completion() {
    local cur opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    opts="-help -uninstall 1 2 3 4 5 6 7 8 9 10"
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
}
complete -F _trackp_completion trackp
EOF
    echo "Bash autocompletion installed at $COMPLETION_FILE."

    # Reload systemd, enable and start the service.
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    systemctl start "$SERVICE_NAME"
    echo "Enabled and started $SERVICE_NAME with default acceleration value: 0.5."
    echo "Installation complete."
    exit 0
fi

# Runtime mode: the script is running from the installed location.
if [ "$#" -eq 0 ]; then
    show_help
    exit 0
fi

# When one argument is provided, treat it as the new acceleration value.
if [ "$#" -eq 1 ]; then
    USER_VAL="$1"

    # Validate that USER_VAL is an integer between 1 and 10.
    if ! [[ "$USER_VAL" =~ ^[1-9]$|^10$ ]]; then
        echo "Invalid acceleration value. Please provide an integer between 1 and 10."
        exit 1
    fi

    # Convert the value by dividing by 10, forcing LC_NUMERIC to C to get a dot as the decimal separator.
    CONV=$(LC_NUMERIC=C awk "BEGIN {printf \"%.1f\", $USER_VAL/10}")

    # Update the service file with the converted acceleration value.
    if [ -f "$SERVICE_FILE" ]; then
        sed -i "s|^ExecStart=.*|ExecStart=/usr/bin/xinput set-prop \"pointer:TPPS/2 IBM TrackPoint\" \"libinput Accel Speed\" ${CONV}|" "$SERVICE_FILE"
        echo "Updated acceleration value to ${CONV} in $SERVICE_FILE."
        systemctl daemon-reload
        systemctl restart "$SERVICE_NAME"
        echo "Restarted $SERVICE_NAME."
    else
        echo "Systemd service file $SERVICE_FILE not found. Please reinstall the script."
        exit 1
    fi
    exit 0
fi

echo "Invalid usage."
show_help
exit 1
