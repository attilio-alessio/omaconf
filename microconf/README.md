# microconf

Native Micro editor configuration installer for Omarchy desktop.

## Overview
microconf installs customized configuration files, keyboard shortcuts, and dynamic Omarchy theme integrations for the Micro terminal editor. All operations are executed using native Bash automation and standard Unix utilities without Python dependencies or external package managers.

## Installation
Execute the native installation script in the user environment to copy and merge settings into the XDG configuration path:
`bash microconf/install.sh`

## Configuration Architecture
Base editor preferences reside in `data/settings.json`, including tab handling, soft wrap, diff gutter, auto-indentation, and the default `"colorscheme": "omarchy"`. Custom key mappings are stored in `data/bindings.json`. Dynamic colorschemes matching active Omarchy themes are populated in `~/.config/micro/colorschemes/` by the theme hook engine. The installer creates automatic timestamped backups before writing new configurations into `~/.config/micro/`.
