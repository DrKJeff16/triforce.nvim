TAGS_CMD = nvim --clean --headless -c 'helptags doc/' -c 'qa!'
LUAROCKS_CMD = luarocks install --local

.POSIX:

.PHONY: all test lint format check help helptags

.SUFFIXES:

all: help

help: ## Show this help message
	@echo -e "Usage: make [target]\n\nAvailable targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo

helptags: ## Generate Neovim helptags
	@echo -e "Generating helptags...\n"
	@$(TAGS_CMD) > /dev/null 2>&1

test: ## Run tests with busted
	@echo "Running tests..."
	@busted spec
	@echo "Done!"

lint: ## Run selene linter
	@echo "Linting with selene..."
	@selene lua
	@echo "Done!"

format: ## Format code with stylua
	@echo "Linting with StyLua..."
	@stylua --check .
	@echo "Done!"

format-fix: ## Format code with stylua (fix)
	@echo "Formatting with StyLua..."
	@stylua .
	@echo "Done!"

check: lint test ## Run linter and tests

install-deps: ## Install development dependencies
	@$(LUAROCKS_CMD) luassert
	@$(LUAROCKS_CMD) busted
	@$(LUAROCKS_CMD) nlua

# vim: set ts=4 sts=4 sw=0 noet ai si sta:
