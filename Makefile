SHELL := /bin/bash

.DEFAULT_GOAL := help

.PHONY: help setup verify test hook icons theme zed micro nvim yazi cli herdr editors clean lang i18n-status lint

lint:
	@if ! command -v shellcheck &> /dev/null; then \
		echo "shellcheck not found. Install with: sudo pacman -S shellcheck (or use CI)"; \
		exit 1; \
	fi
	shellcheck --severity=style \
		scripts/*.sh scripts/lib/*.sh scripts/modules/*.sh \
		hooks/theme-set.d/* hooks/pre-refresh-pacman.d/* hooks/post-update.d/* \
		zedconf/*.sh microconf/*.sh nvimconf/*.sh yaziconf/*.sh cliconf/*.sh herdrconf/*.sh \
		tests/*.sh

help:
	@bash scripts/lib/help.sh

setup:
	sudo bash scripts/setup.sh

verify:
	bash scripts/verify.sh

test:
	bash tests/run-all.sh

hook:
	@mkdir -p ~/.config/omarchy/hooks/theme-set.d ~/.config/omarchy/hooks/i18n/messages
	cp hooks/theme-set.d/* ~/.config/omarchy/hooks/theme-set.d/
	chmod +x ~/.config/omarchy/hooks/theme-set.d/*
	cp scripts/lib/i18n.sh scripts/lib/i18n-boot.sh ~/.config/omarchy/hooks/i18n/
	cp scripts/lib/messages/*.msg ~/.config/omarchy/hooks/i18n/messages/

icons:
	@bash hooks/theme-set.d/folder-color

theme:
	@bash hooks/theme-set.d/folder-color
	@bash hooks/theme-set.d/micro-theme

zed:
	bash zedconf/install.sh

micro:
	bash microconf/install.sh

nvim:
	bash nvimconf/install.sh

yazi:
	bash yaziconf/install.sh

cli:
	bash cliconf/install.sh

herdr:
	bash herdrconf/install.sh

editors: zed micro nvim cli

lang:
	@bash scripts/lib/i18n.sh --list

i18n-status:
	@bash scripts/lib/i18n.sh

clean:
	rm -f setup.log
