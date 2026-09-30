# nvimconf

Native Neovim helper layer for omarchy nvim config.

## Overview

nvimconf keeps stock omarchy nvim setup intact and adds two owned files with memory friendly helpers and keywords only completion. All operations run in user scope with native Bash and standard Unix tools.

## Installation

Run in user scope after neovim and omarchy nvim packages exist:

```bash
bash nvimconf/install.sh
```

## Architecture

Installer seeds user nvim config from skel when missing, then installs helper lua and completion lua into plugins folder with timestamped backup of prior copy. Completion disables buffer source so suggestions come from LSP keywords and paths and snippets only, never buffer words. Helper sets absolute only line numbers and fast which key popup and registers English which key groups and helper leader group with searchable cheatsheet and shortcuts to Lazy and Mason and diagnostics and registers and command history. Zero new plugins download as which key and Snacks already ship with base. Theme switching regenerates only theme lua, so helpers survive each theme set across all themes.
