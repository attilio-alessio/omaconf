---
name: editor-configurations
description: >-
  Procedures and standards for managing, installing, and synchronizing native configurations for Zed, Micro, Neovim and Yazi in Omarchy.
---

# Editor Configurations

## Overview
This skill provides guidelines and procedures for maintaining modular native configurations for text editors and terminal tools in Omarchy. The `zedconf/` module owns the Zed editor, `microconf/` owns the Micro terminal editor, `nvimconf/` owns the Neovim stack and `yaziconf/` owns the Yazi file manager. Every module keeps its own data files under `data/` and exposes exactly one user scope installer at its root, so a rule about an editor's configuration has exactly one home.

## Shared Installer Contract
All four installers are built on `scripts/lib/userconf.sh`, which owns the three patterns they share. Installing a file keeps a single slot backup of the replaced content instead of an unbounded series of timestamped copies, so repeated installs converge instead of accumulating. Installing content from a stream writes atomically and falls back cleanly. Replacing a marked shell block removes the previous marked range and rewrites it in place, which keeps the shell profile stable across runs.

When adding a module, call those helpers rather than reimplementing `mkdir`, `cp` and a `sed` range delete. The modular suites assert that no installer reintroduces the ad hoc timestamped backup and that every installer sources the shared library.

## Zed
The Zed data directory holds a base settings file covering appearance, tab sizes, formatting and language servers, a Linux specific overlay for fonts and keymap behaviour, a universal keymap file, optional language snippets and the runner definitions. The installer merges the base settings with the Linux overlay through `jq` when it is available and otherwise installs the base settings, then deploys the keymap and the snippets when they exist.

## Micro
The Micro data directory holds an editor settings file and a key bindings file. The installer merges the shipped settings into the existing ones so user edits survive, and falls back to a clean copy when the merge is not possible or the existing file is not valid JSON. It then installs the key bindings and adds the editor helper to the shell profile.

## Neovim
The Neovim module seeds a base configuration from the Omarchy skel only when the user has none, then installs the helper and completion plugins as managed files. Because the theme stage rewrites the Yazi configuration during a full setup, re-run the obscurity sub-project afterwards so its gate reflects the new files.

## Yazi
The Yazi module installs its own configuration and theme, deploys the terminal desktop file so the file manager also serves the desktop open and save dialogs, registers the directory handler and adds its helpers to the shell profile.

## Operational Workflow
Install a single module through its Makefile target or by running the module installer directly, and install all of them with the aggregate target. Synchronize the Micro colorscheme with the active theme through the theme target or by running the Micro theme hook.
