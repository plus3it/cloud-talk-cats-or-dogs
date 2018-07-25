MAKEFLAGS += --no-print-directory
MAKEFLAGS += --quiet
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

XARGS_CMD := xargs -I {}
BIN_DIR := ${HOME}/bin
PATH := $(BIN_DIR):${PATH}

TF_MODULES := iam bucket main
TF_COMMANDS := apply plan destroy validate

guard-% :
	@ if [ "${${*}}" = "" ]; then \
		echo "[make] ERROR: Make/environment variable '$*' not set"; \
		exit 1; \
	fi

tools/json: JQ_URL := https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
tools/json:
	curl -sSL "$(JQ_URL)" -o jq
	chmod +x ./jq
	mv ./jq "$(BIN_DIR)"
	jq --version

test:
	@echo "[make]: Running tests..."
	$(MAKE) test/tf/fmt test/json/lint
	$(MAKE) test/tf/validate
	@echo "[make]: Passed tests!"

test/json/%: FIND_JSON := find . -not \( -name .terraform -prune \) -name '*.json' -type f
test/json/lint:
	@echo "[make] Linting JSON files..."
	$(FIND_JSON) | $(XARGS_CMD) bash -c 'cmp {} <(jq --indent 4 -S . {}) || (echo "[{}]: Failed JSON Lint Test"; exit 1)'
	@echo "[make] JSON files PASSED lint test!"

test/tf/fmt:
	@echo "[make]: Checking terraform format..."
	terraform fmt -check=true
	@echo "[make]: Passed terraform format test!"

test/tf/validate:
	$(MAKE) validate/all
	@echo "[make]: Passed terraform validation test!"

init: upgrade := false
init: guard-module
	@echo "[make]: Running terraform command 'init' in module '$(module)', upgrade=$(upgrade)..."
	cd $(module) && terraform init -upgrade=$(upgrade)

$(TF_COMMANDS): guard-module init
	@echo "[make]: Running terraform command '$@' in module '$(module)'..."
	cd $(module) && terraform $@
	@echo "[make]: Successfully completed 'terraform  $@' in module '$(module)'!"

# Support targets of the form "<command>/<module>"
# E.g. `make apply/iam`
%:
	@echo "[make]: Wildcard target input: '$*'"
	$(MAKE) $(@D) module=$(@F)

# Support running a terraform command on all modules"
# E.g. `make validate/all`
%/all: TARGETS=$(shell for MODULE in $(TF_MODULES); do echo $(@D)/$$MODULE; done)
%/all:
	@echo "[make]: Running make targets '$(TARGETS)'..."
	$(MAKE) $(TARGETS)
