LUAROCKS_CMD = luarocks install --local

.POSIX:

.PHONY: all test lint format check help

.SUFFIXES:

all: help

help: ## Show this help message
	@echo -e "Usage: make [target]\n\nAvailable targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

test: ## Run tests with busted
	@echo -e "Running tests...\n"
	@busted spec
	@echo -e "\nDone!"

lint: ## Run selene linter
	@echo -e "Linting with selene...\n"
	@selene lua
	@echo -e "\nDone!"

format: ## Format code with stylua
	@echo -e "Linting with StyLua...\n"
	@stylua --check .
	@echo -e "\nDone!"

format-fix: ensure_eof ## Format code with stylua (fix)
	@echo -e "Formatting with StyLua...\n"
	@stylua .
	@echo "Done!"

check: lint test ## Run linter and tests

install-deps: ## Install development dependencies
	@$(LUAROCKS_CMD) luassert
	@$(LUAROCKS_CMD) busted
	@$(LUAROCKS_CMD) nlua

# vim: set ts=4 sts=4 sw=0 noet ai si sta:
