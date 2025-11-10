.PHONY: all test lint format check help

all: help

help: ## Show this help message
	@echo -e "Usage: make [target]\n"
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

test: ## Run tests with busted
	busted

lint: ## Run luacheck linter
	luacheck .

lint-selene: ## Run selene linter
	selene .

format: ## Format code with stylua
	stylua --check .

format-fix: ## Format code with stylua (fix)
	stylua .

check: lint test ## Run linter and tests

install-deps: ## Install development dependencies
	luarocks install --local busted
	luarocks install --local nlua
	luarocks install --local luacheck
