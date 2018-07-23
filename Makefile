MAKEFLAGS += --no-print-directory
MAKEFLAGS += --quiet
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

TF_MODULES := iam bucket main
TF_COMMANDS := apply plan destroy validate

guard-% :
	@ if [ "${${*}}" = "" ]; then \
		echo "[make] ERROR: Make/environment variable '$*' not set"; \
		exit 1; \
	fi

test:
	@echo "[make]: Running tests..."
	$(MAKE) test/tf/fmt
	$(MAKE) test/tf/validate
	@echo "[make]: Passed tests!"

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
