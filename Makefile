LUAROCKS_CMD = luarocks install --local

.POSIX:

.PHONY: all test lint format check help ensure_eof

all: help

help: ## Show this help message
	@echo -e "Usage: make [target]\n\nAvailable targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

test: ## Run tests with busted
	@busted

lint: ## Run selene linter
	@selene lua

format: ## Format code with stylua
	@stylua --check .

format-fix: ensure_eof ## Format code with stylua (fix)
	@stylua .

ensure_eof: scripts/ensure_eof_comment.py ## Run EOF checker script
	@python scripts/ensure_eof_comment.py

check: lint test ## Run linter and tests

install-deps: ## Install development dependencies
	@$(LUAROCKS_CMD) luassert
	@$(LUAROCKS_CMD) busted
	@$(LUAROCKS_CMD) nlua
