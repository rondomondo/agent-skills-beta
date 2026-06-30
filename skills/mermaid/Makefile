# mermaid Skill Makefile

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
ZIP_DIR           := ../zipped/mermaid
ZIP_FILES         := SKILL.md Makefile README.md scripts examples data references

# Tooling
MERMAID_SCRIPT    := $(SKILL_SCRIPTS_DIR)/mermaid.sh
MERMAID_IMAGE     ?= minlag/mermaid-cli:latest
TEST_INPUT        ?= examples/example.md

.PHONY: help
help: ## Display this help message
	@printf "\nUsage: make $(CYAN)<target>$(RESET)\n"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  $(CYAN)%-15s$(RESET) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BOLD)%s$(RESET)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: check
check: ## Check that Docker is running and the mermaid function sources correctly
	@printf "Checking Docker... "
	@if docker info >/dev/null 2>&1; then \
		printf "$(GREEN)ok$(RESET)\n"; \
	else \
		printf "$(RED)Docker is not running$(RESET)\n"; exit 1; \
	fi
	@printf "Checking mermaid function... "
	@if bash -c 'source $(MERMAID_SCRIPT) 2>/dev/null && type mermaid' >/dev/null 2>&1; then \
		printf "$(GREEN)ok$(RESET)\n"; \
	else \
		printf "$(RED)not found — check $(MERMAID_SCRIPT)$(RESET)\n"; exit 1; \
	fi

.PHONY: pull-image
pull-image: ## Pre-pull the minlag/mermaid-cli Docker image
	@printf "$(CYAN)Pulling$(RESET) $(MERMAID_IMAGE)...\n"
	@docker pull $(MERMAID_IMAGE)
	@printf "$(GREEN)Image ready$(RESET)\n"

.PHONY: test
test: check ## Render TEST_INPUT as SVG and PNG to verify the full pipeline (override: TEST_INPUT=examples/foo.md)
	@printf "$(BOLD)$(CYAN)--- SVG render ---$(RESET)\n"
	@bash -c 'source $(MERMAID_SCRIPT) && mermaid $(TEST_INPUT) -f svg'
	@printf "$(BOLD)$(CYAN)--- PNG render ---$(RESET)\n"
	@bash -c 'source $(MERMAID_SCRIPT) && mermaid $(TEST_INPUT) -f png --width 960 --height 640'
	@printf "$(GREEN)Test renders complete$(RESET)\n"

.PHONY: clean
clean: ## Remove rendered output files from examples/ and data/
	@printf "$(CYAN)Removing$(RESET) rendered output files...\n"
	@find examples/ data/ -type f \( -name "*.svg.md" -o -name "*.png.md" -o -name "*.pdf.md" \
	  -o -name "*.svg-[0-9]*.svg" -o -name "*.png-[0-9]*.png" \) -delete 2>/dev/null || true
	@printf "$(GREEN)Clean$(RESET)\n"

.PHONY: doctor
doctor: ## Show environment info useful for bug reports
	@printf "$(BOLD)mermaid doctor$(RESET)\n\n"
	@printf "  Shell:         %s\n" "$$SHELL"
	@printf "  Script:        "; ls -lh "$(MERMAID_SCRIPT)" 2>/dev/null || printf "$(RED)not found$(RESET)\n"
	@printf "  Docker:        "; docker --version 2>/dev/null || printf "$(RED)not found$(RESET)\n"
	@printf "  Docker running: "; docker info >/dev/null 2>&1 && printf "$(GREEN)yes$(RESET)\n" || printf "$(RED)no$(RESET)\n"
	@printf "  mermaid-cli image: "; docker image inspect minlag/mermaid-cli --format '{{.RepoTags}} ({{.Id}})' 2>/dev/null || printf "not pulled (run make pull-image)\n"
	@echo ""

.PHONY: zip-prep
zip-prep: ## Copy distributable files to ZIP_DIR (../zipped/mermaid) ready for zipping
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
