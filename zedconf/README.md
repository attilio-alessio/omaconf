# zedconf

Native Zed editor configuration installer for Omarchy desktop.

## Overview
zedconf installs customized configuration files, themes, keymaps, and code runners into the Zed editor configuration directory. All installations are performed using native Bash automation and standard Unix utilities without Python dependencies or virtual environments.

## Installation
Execute the native installation script in the user environment to copy and merge settings into the XDG configuration path:
`bash zedconf/install.sh`

## Configuration Architecture
Base editor preferences reside in `data/settings.json` while platform overrides reside in `data/linux/settings.json`. Custom key mappings are stored in `data/keybindings.json` and code snippets reside in `data/snippets/`. The installer creates automatic timestamps backups before writing new configurations into `~/.config/zed/`.