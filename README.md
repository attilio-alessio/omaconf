# omablot

Arch Linux security hardening, debloat and theming automation for Omarchy.

## Overview
omablot provisions and maintains a hardened Omarchy desktop through native Bash automation and standard system utilities. The pipeline applies kernel and authentication hardening, firewall policy, intrusion prevention tooling, package debloating with persistent defaults, per theme desktop integration and battery health enforcement. Every operation is idempotent and verifiable.

## Repository Architecture
The repository is organized into functional components under dedicated paths. The `scripts/` directory holds modular root provisioning (`scripts/modules/`), verification, compatibility testing and launcher scripts. The `tests/` directory holds modular suites covering syntax integrity, desktop services, lockscreen safety, kernel parameters, authentication, firewall isolation, debloat theming, power policy, pipeline shape and automation safety, orchestrated by `tests/run-all.sh`. Continuous integration under `.github/workflows/ci.yml` runs syntax linting and regression testing on every change. The `hooks/` directory holds Omarchy desktop integration for folder colors, Micro editor themes and system monitor themes. The `zedconf/`, `microconf/`, `nvimconf/`, `yaziconf/` and `cliconf/` directories hold native configuration modules and installers for the Zed, Micro and Neovim editors, the Yazi file manager and the CLI shell helpers. Each module owns its data files and exposes a single user-scope `install.sh`. Operational runbooks live in `.skills/` and project workflows are exposed through the `Makefile`.

## Execution Workflows
System operations run through the standard Makefile targets. Running `make setup` executes the full hardening and provisioning pipeline as root. Running `make verify` checks the security posture against the expected kernel, service and package assertions. Running `make test` executes the modular test suite (`bash tests/run-all.sh`). Running `make hook` installs the desktop theme hooks and the i18n runtime for the current user, `make icons` forces an immediate color update for the active theme and `make theme` synchronizes folder icons with editor themes. Running `make zed`, `make micro`, `make nvim`, `make yazi` or `make cli` installs the individual configuration module (or `make editors` for all of them). `make lang` lists the supported languages, `make i18n-status` reports the resolved catalog and `make clean` purges local execution logs.

## Provisioning Modules
`scripts/setup.sh` runs as root, opens a log in append mode, resolves the primary user and sources every stage module below in a fixed order. Each module degrades gracefully and is individually idempotent.

- `00-env.sh` syncs the package database, repairs broken pacman entries, defines `aur_verified_install` for integrity-checked AUR builds and `omarchy_as` to launch Omarchy commands inside a real user session with the correct `XDG_RUNTIME_DIR` and D-Bus bus.
- `05-locale.sh` derives the locale, console keymap and XKB layout from the system timezone.
- `10-debloat.sh` removes stock packages with a normal-then-forced fallback, writes the dedicated pin list, merges pins into `pacman.conf` with zero duplicates, cleans the Omarchy base package list, removes portal overrides and installs the per-user persistence hooks.
- `20-defaults.sh` installs Brave, Micro and mpv, sets the browser, editor, media player and file manager defaults per user, patches `mimeapps.list` and registers the Hypr bindings. The `inode/directory` default resolves to `yazi-terminal.desktop` when the yaziconf installer deployed it, otherwise it falls back to the system `yazi.desktop`.
- `30-theming.sh` creates the per-home theme hook folder, removes leftover color state, copies the hooks with executable bits and fixes ownership.
- `32-omaqt.sh` is opt-in: it logs a clean skip and returns unless `OMAQT_URL` is set. When it is, the module clones or updates that repository in `$OMAQT_DIR` (default `/usr/share/omarchy/omaqt`) and runs its installer. `OMAQT_DIR` overrides the checkout location.
- `33-nvim.sh` unpins the Neovim stack, installs it when absent and provisions the nvimconf helpers for every user.
- `35-shell-plugins.sh` reads the per-user plugin list as JSON and adds the media plugin to the right bar section.
- `40-firewall.sh` through `95-maintenance.sh` own the firewall, kernel, authentication, SSH, service, security tooling, hardware power and maintenance stages.

## Configuration Modules
Each module owns its data files and a single user-scope installer.

- `cliconf` copies the shared shell helpers and adds a marked source block to `bashrc`, exposing `helper <name>` quick cards for mpv, zathura, imv, fzf, rg, fd, bat, eza, zoxide, git, lazygit, gum and ai.
- `microconf` merges `settings.json` with `jq` and conditional backup, copies `bindings.json`, launches the Micro theme hook and adds the `mh` helper.
- `zedconf` merges base and Linux settings, copies the keymap and installs snippets when present.
- `yaziconf` copies `yazi.toml` and `theme.toml` with conditional backup, installs `yazi-terminal.desktop` as the desktop file manager, registers the `inode/directory` handler and adds the `ya` and `yh` helpers.
- `nvimconf` seeds the base config from the Omarchy skel when missing and installs the helper and completion Lua plugins with backup.

## Theme and Persistence Hooks
`hooks/theme-set.d/` holds the folder color, shell icon, Micro theme, Yazi theme, CLI theme and btop theme hooks. Each resolves the current theme name from `~/.local/state/omarchy/current/theme.name` and picks the light or dark family accordingly. `hooks/pre-refresh-pacman.d/` and `hooks/post-update.d/` hold the persistence hooks that re-merge the pins, re-apply the removals, reset the MIME defaults, restore the terminal file chooser portal routing and mask the Omarchy crash watcher.

## Security Posture and Kernel Protections
Kernel security is enforced via `/etc/sysctl.d/99-security.conf` with full address space randomization, restricted kernel pointers, restricted dmesg buffers, disabled unprivileged eBPF execution, restricted ptrace debugging and SysRq limited to emergency sync. Filesystem protection disables setuid core dumps and enforces strict ownership checks on symlinks, hardlinks, FIFOs and regular files in sticky directories. Network protections include reverse path filtering, disabled redirects and source routing, ignored broadcast echo requests and active TCP SYN cookies with RFC 1337 TIME WAIT handling.

## Access Control and System Hardening
Authentication locks accounts after five consecutive failed attempts for fifteen minutes via `/etc/security/faillock.conf`, password complexity is required via `pwquality.conf` and core dumps are disabled globally. SSH denies root login and password authentication while enforcing modern ciphers, and the daemon is isolated through systemd drop-ins with strict filesystem and privilege restrictions. The UFW firewall denies incoming traffic by default and allows outgoing. Host tooling integrates AppArmor mandatory access control, auditd logging, fail2ban monitoring, USBGuard device authorization, ClamAV scanning and weekly automated Lynis audits.

## Desktop Parity and Debloat Strategy
Theming keeps the system monitor, folder colors, the Papirus icon theme and the Capitaine cursor in sync with the active palette, and generates Micro editor colorschemes dynamically from the current theme. Yazi is the default file manager and also serves desktop open and save dialogs through a terminal file chooser portal backed by Kitty. Foot is removed from the default package set. The pipeline removes unneeded stock packages such as Chromium, Kdenlive, OBS Studio, LibreOffice, Obsidian and GNOME utilities, replacing them with lightweight defaults including Brave, Kitty, Micro, Yazi, imv, mpv, Zathura and btop. Removed packages stay pinned under `IgnorePkg` in `/etc/pacman.conf` and obsolete web application shortcuts are cleaned from application directories. MIME defaults are registered per user for directories, PDF, images and video, Hypr bindings gain a Yazi launcher behind a dedicated marker, and the shell bar gains the media plugin on the right in first position.

## Internationalization
Every human-readable string in the scripts, hooks and installers is referenced by a symbolic key resolved through `scripts/lib/i18n.sh`, with catalogs for English, Italian, French, German, Spanish and Portuguese under `scripts/lib/messages/`. The active language is resolved from `OMABLOT_LANG` first, then the standard `LANGUAGE`, `LC_ALL`, `LC_MESSAGES` and `LANG` variables, and finally `/etc/locale.conf`. English is always loaded first and acts as the fallback.

## Battery Health and Power Management
Battery longevity enforces a perpetual 75 percent charging threshold defined in `/etc/omablot/power.conf`. The policy covers supported batteries and persists across boot, suspend and resume, hotplug and system updates through Udev rules, systemd tmpfiles initialization, a shared sysfs helper and a resume hook. Systems that expose deep sleep use it to reduce suspend drain; the setting is not forced on hardware that does not advertise it.
