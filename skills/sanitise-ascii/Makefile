# sanitise-ascii Skill Makefile

# Colours
BOLD   := \033[1m
RED    := \033[31m
GREEN  := \033[32m
CYAN   := \033[36m
YELLOW := \033[33m
RESET  := \033[0m

# Common Configuration
MAKEFLAGS         += --no-print-directory
SHELL             := /bin/bash
SKILL_DIR         := .
SKILL_SCRIPTS_DIR := $(SKILL_DIR)/scripts

# Distribution Helpers
ZIP_DIR           := ../zipped/sanitise-ascii
ZIP_FILES         := SKILL.md Makefile scripts .githooks README.md

# Tooling
PYTHON            := python3
SANITISE_SCRIPT   := $(SKILL_SCRIPTS_DIR)/sanitise-ascii.py

.PHONY: help
help: ## Display this help message
	@printf "\nUsage: make $(CYAN)<target>$(RESET)\n"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  $(CYAN)%-15s$(RESET) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BOLD)%s$(RESET)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: check
check: ## Check all .md files under skills/ for non-ASCII (no writes)
	@printf "$(CYAN)[check]$(RESET) Scanning .md files...\n"
	@$(PYTHON) $(SANITISE_SCRIPT) --check --dir ../../skills && \
		printf "$(GREEN)[check]$(RESET) All files are ASCII-clean\n"

.PHONY: fix
fix: ## Fix known non-ASCII characters in all .md files under skills/
	@printf "$(CYAN)[fix]$(RESET) Sanitising .md files...\n"
	@$(PYTHON) $(SANITISE_SCRIPT) --dir ../../skills
	@printf "$(GREEN)[fix]$(RESET) Done\n"

.PHONY: fix-file
fix-file: ## Fix a single file: make fix-file FILE=path/to/file.md
	@if [ -z "$(FILE)" ]; then printf "$(RED)ERROR:$(RESET) FILE is required. Usage: make fix-file FILE=path/to/file.md\n"; exit 1; fi
	@$(PYTHON) $(SANITISE_SCRIPT) $(FILE)
	@printf "$(GREEN)[fix-file]$(RESET) Done -> $(FILE)\n"

.PHONY: install-hook
install-hook: ## Install pre-commit hook into current repo (.git/hooks/)
	@printf "$(CYAN)[install-hook]$(RESET) Installing hook...\n"
	@cp .githooks/pre-commit-sanitise-ascii ../../.git/hooks/pre-commit-sanitise-ascii
	@chmod +x ../../.git/hooks/pre-commit-sanitise-ascii
	@printf "$(GREEN)[install-hook]$(RESET) Installed -> .git/hooks/pre-commit-sanitise-ascii\n"

.PHONY: install-hook-global
install-hook-global: ## Install pre-commit hook globally (~/.githooks/)
	@printf "$(CYAN)[install-hook-global]$(RESET) Installing global hook...\n"
	@mkdir -p ~/.githooks
	@cp .githooks/pre-commit-sanitise-ascii ~/.githooks/pre-commit-sanitise-ascii
	@chmod +x ~/.githooks/pre-commit-sanitise-ascii
	@cp $(SANITISE_SCRIPT) ~/sanitise-ascii.py
	@git config --global core.hooksPath ~/.githooks
	@printf "$(GREEN)[install-hook-global]$(RESET) Hook installed; script copied to ~/sanitise-ascii.py\n"

.PHONY: zip-prep
zip-prep: ## Copy distributable files to ZIP_DIR (../zipped/sanitise-ascii) ready for zipping
	@printf "$(CYAN)Preparing zip staging dir:$(RESET) $(ZIP_DIR)\n"
	@/bin/rm -rf $(ZIP_DIR)
	@mkdir -p $(ZIP_DIR)
	@ok=0; fail=0; \
	for f in $(ZIP_FILES); do \
		if /bin/cp -R $$f $(ZIP_DIR)/ 2>/dev/null; then \
			printf "  $(GREEN)ok$(RESET)  $$f\n"; ok=$$((ok+1)); \
		else \
			printf "  $(RED)FAIL$(RESET)  $$f\n"; fail=$$((fail+1)); \
		fi \
	done; \
	printf "\n  $(BOLD)$$ok copied, $$fail failed$(RESET) -> $(ZIP_DIR)\n"; \
	[ $$fail -eq 0 ]
