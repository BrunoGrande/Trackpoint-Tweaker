# Trackp Deployment Script

## Overview

The **Trackp Deployment Script** automates the installation, configuration, and management of a custom TrackPoint acceleration setting for Linux systems. The script:

- **Ensures Root Access:** Verifies that the script is run as root.
- **Installs the Trackp Script:** Copies itself to `/usr/local/bin/trackp` so it can be run as a command.
- **Creates a Systemd Service Unit:** Sets up a one-shot service to run the TrackPoint acceleration adjustment using `xinput`.
  - The unit is configured to run after the graphical target (ensuring that X11 is available).
  - It explicitly sets the `DISPLAY` and `XAUTHORITY` environment variables.
- **Numeric Value Conversion:** Accepts an integer value from 1 to 10 and converts it to a decimal between 0.1 and 1.0 for the `libinput Accel Speed` property.
- **Bash Autocompletion:** Installs a Bash completion file to **/etc/bash_completion.d/trackp** so that autocompletion is available by default.
- **Command-Line Options:** Provides built-in options:
  - **`-help`**: Displays usage instructions.
  - **`-uninstall`**: Removes the installed script, its systemd service, and the Bash autocompletion file.

## Installation

1. **Download the Script:**  
   Save the deployment script (e.g., as `/home/$USER/Downloads/Trackp.sh`).

2. **Make It Executable:**
   ```bash
   sudo chmod +x /home/$USER/Downloads/Trackp.sh
   ```

3. **Run the Script as Root:**  
   From its original location, install the script by running:
   ```bash
   sudo /home/$USER/Downloads/Trackp.sh
   ```
   This action will:
   - Copy the script to `/usr/local/bin/trackp`
   - Create and enable a systemd service that applies a default acceleration value of `0.5`
   - Install a Bash autocompletion file in **/etc/bash_completion.d/trackp**

4. **Verify Installation:**  
   Open a new terminal (or source the Bash completion file with `source /etc/bash_completion.d/trackp`) and type:
   ```bash
   trackp [TAB]
   ```
   to see available completions. You can then update the TrackPoint acceleration by running:
   ```bash
   sudo trackp <value>
   ```
   where `<value>` is an integer between 1 and 10 (e.g., `sudo trackp 6` sets the acceleration to `0.6`).

## Usage

### Command-Line Options

- **Update Acceleration Value:**  
  ```bash
  sudo trackp <acceleration_value>
  ```
  *Example:*  
  ```bash
  sudo trackp 6
  ```
  This converts the input to `0.6` and updates the systemd service accordingly.

- **Help:**  
  ```bash
  sudo trackp -help
  ```
  Displays the usage information.

- **Uninstall:**  
  ```bash
  sudo trackp -uninstall
  ```
  Uninstalls the Trackp script, stops and disables the systemd service, and removes the Bash autocompletion file.

## How It Works

- **Systemd Service:**  
  The service unit is defined to run after the graphical session is up. It sets the following environment variables:
  - `DISPLAY=:0`
  - `XAUTHORITY=/home/vex/.Xauthority`
  
  It then runs the command:
  ```bash
  xinput set-prop "pointer:TPPS/2 IBM TrackPoint" "libinput Accel Speed" <value>
  ```
  where `<value>` is a floating‑point number (0.1–1.0).

- **Numeric Conversion:**  
  The script accepts an integer (1–10) from the user, converts it by dividing by 10 (using a forced locale so that the decimal separator is a dot), and updates the ExecStart command in the service unit.

- **Bash Autocompletion:**  
  A completion file is installed in **/etc/bash_completion.d/trackp**, which provides suggestions for options (`-help`, `-uninstall`) and numbers (1–10) when using the `trackp` command.

## Uninstallation

To remove all installed components, run:
```bash
sudo trackp -uninstall
```
This command will:
- Stop and disable the `trackp.service`
- Remove the service file and its symlink
- Delete the installed script from `/usr/local/bin/trackp`
- Remove the Bash autocompletion file from **/etc/bash_completion.d/trackp**

## Requirements

- **Linux Mint (or compatible Linux distribution) with Cinnamon on X11.**
- **xinput:** Ensure this utility is installed.
- **Root Privileges:** The script and its components require root access.

## Logging

The script provides output to the console. For troubleshooting systemd-related issues, consult the logs using:
```bash
journalctl -xeu trackp.service
```

## License

This project is licensed under the MIT License.

## Author

Bruno Bellizzi Grande  
*Last updated: March 13, 2025*
