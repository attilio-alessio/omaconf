.PHONY: debloat-ai test help

SHELL := /bin/bash

help:
	@printf '%s\n' "debloat-ai  Opt-in AI debloat (explicit request only)"
	@printf '%s\n' "test        Run integrity checks"

debloat-ai:
	sudo bash scripts/debloat-ai.sh --yes

test:
	bash tests/check.sh
