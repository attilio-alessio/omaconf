SHELL := /bin/bash

.DEFAULT_GOAL := help

.PHONY: help setup verify test hook icons theme zed micro nvim yazi cli editors clean lang i18n-status

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

editors: zed micro nvim cli

lang:
	@bash scripts/lib/i18n.sh --list

i18n-status:
	@bash scripts/lib/i18n.sh

clean:
	rm -f setup.log
