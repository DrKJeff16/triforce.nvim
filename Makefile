LUAROCKS_CMD = luarocks install --local

.PHONY: all test lint format check help

all: help

help: ## Show this help message
	@echo -e "Usage: make [target]\n"
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

test: ## Run tests with busted
	@busted

lint: ## Run selene linter
	selene lua

format: ## Format code with stylua
	stylua --check .

format-fix: ## Format code with stylua (fix)
	stylua .

check: lint test ## Run linter and tests

install-deps: ## Install development dependencies
	$(LUAROCKS_CMD) luassert
	$(LUAROCKS_CMD) busted
	$(LUAROCKS_CMD) nlua
