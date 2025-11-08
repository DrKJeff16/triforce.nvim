.PHONY: test lint format check help

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

test: ## Run tests with busted
	busted

lint: ## Run luacheck linter
	luacheck .

format: ## Format code with stylua
	stylua --check .

format-fix: ## Format code with stylua (fix)
	stylua .

check: lint test ## Run linter and tests

install-deps: ## Install development dependencies
	luarocks install --local busted
	luarocks install --local nlua
	luarocks install --local luacheck
