# yaziconf

Native Yazi terminal file manager configuration installer for Omarchy.

## Overview

The installer runs as the target user and copies `data/yazi.toml` and `data/theme.toml` into the user Yazi configuration directory, keeping a timestamped backup of any differing previous file. It also installs `data/yazi-terminal.desktop` as the desktop file manager entry, registers it as the `inode/directory` default handler, and ensures the `ya` shell wrapper exists exactly once inside `bashrc` so that quitting Yazi leaves the shell in the last visited directory. The `yh` helper prints a terminal quick card for Yazi keybindings and the matching openers.

Openers stay aligned with the omaconf desktop stack using micro for text and markdown, Zathura for PDF, imv for images, and mpv for audio and video.

## Installation

Run in user scope:

```bash
bash yaziconf/install.sh
```

Or through the Makefile:

```bash
make yazi
```

## Architecture

```
yaziconf/
├── data/
│   ├── yazi.toml
│   ├── theme.toml
│   └── yazi-terminal.desktop
└── install.sh
```
