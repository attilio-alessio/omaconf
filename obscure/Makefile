.PHONY: setup verify test clean help

SHELL := /bin/bash

help:
	@printf '%s\n' "setup       Run full setup (root)"
	@printf '%s\n' "verify      Run verification checks"
	@printf '%s\n' "test        Run comprehensive test suites"
	@printf '%s\n' "clean       Remove setup log"

setup:
	pkexec bash scripts/setup.sh

verify:
	bash scripts/verify.sh

test:
	bash tests/run-all.sh

clean:
	rm -f setup.log
