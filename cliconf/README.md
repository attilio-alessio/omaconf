# cliconf

Native CLI helper installer for omablot terminal stack.

## Overview

cliconf installs helper command with English cheatsheet per tool in the stack. Tools with built in help stay referenced with never duplicated text. All operations run in user scope with native Bash and standard Unix tools.

## Installation

Run in user scope:

```bash
bash cliconf/install.sh
```

## Architecture

Installer copies data helpers into shared omablot path and registers marked source block in bashrc with markers refreshed idempotently on each run. Helper list prints tool index and helper with name prints section for mpv and zathura and imv and fzf and rg and fd and bat and eza and zoxide and git and lazygit and gum and built in pointers for yazi and micro and nvim. Terminal helpers for yazi and micro arrive with sibling confs.
