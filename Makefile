MAKEFLAGS += --no-print-directory
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

TF_COMMANDS = apply plan destroy

guard-% :
	@ if [ "${${*}}" = "" ]; then \
		echo "[make] ERROR: Make/environment variable '$*' not set"; \
		exit 1; \
	fi

init: upgrade = true
plan apply: init

init: guard-module
	@echo "[make]: Running terraform command 'init' in module '$(module)', upgrade=$(upgrade)..."
	@cd $(module) && terraform init -upgrade=$(upgrade)

$(TF_COMMANDS): guard-module
	@echo "[make]: Running terraform command '$@' in module '$(module)'..."
	@cd $(module) && terraform $@

# Support targets of the form "<command>/<module>"
# E.g. `make apply/iam`
%:
	@echo "[make]: Wildcard target input: '$*'"
	@$(MAKE) $(@D) module=$(@F)
