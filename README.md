# Trackpoint-Tweaker

## Overview

Trackpoint-Tweaker is a lightweight CLI tool that fine-tunes ThinkPad TrackPoint acceleration settings on Linux via `xinput`. It maps simple scale values (1–10) to acceleration levels between 0.1 and 1.0, automatically installs bash autocomplete, and supports a self-uninstall option. Designed for ThinkPad users, it applies the desired setting only if it hasn’t been set already, ensuring a smooth experience after boot or resume.

## Features

- **Simple CLI:** Adjust TrackPoint acceleration using a single command (e.g., `sudo trackp 5`).
- **Bash Auto-Completion:** Automatically installs a completion snippet to suggest scale values (1–10).
- **Self-Uninstall:** Easily remove the auto-completion file and the script itself with `sudo trackp -uninstall`.
- **Idempotent Operation:** Checks current settings to avoid redundant changes after boot or resume.
- **Optimized for ThinkPads:** Defaults to using the "TPPS/2 IBM TrackPoint" device name.

## Installation

1. **Download the Script:**  
   Clone or download the repository containing the `trackp` script.

2. **Copy to /usr/local/bin:**  
   ```bash
   sudo cp trackp /usr/local/bin/
