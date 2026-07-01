PROFILE ?= starter
MODEL ?=

.DEFAULT_GOAL := help

.PHONY: help install models model-list run serve health chat chat-openai py-chat demo clean uninstall

help: ## Show this help.
	@printf "Available targets:\n"
	@grep -E '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"} {printf "  %-14s %s\n", $$1, $$2}'

install: ## Install Azure AI Foundry Local on macOS.
	bash scripts/install-mac.sh

models: ## Download a model profile, set PROFILE=starter, balanced, or power.
	bash scripts/download-models.sh --profile "$(PROFILE)" --yes

model-list: ## List models from Foundry Local.
	bash scripts/list-models.sh

run: ## Run an interactive model REPL, set MODEL=alias or leave empty for default.
	bash scripts/run-model.sh "$(MODEL)"

serve: ## Start service and print dynamic endpoint with curl example.
	bash scripts/serve.sh

health: ## Run local Foundry health checks.
	bash scripts/health-check.sh

chat: ## Run the native JavaScript SDK chat example.
	cd examples/js && npm install && node chat.mjs

chat-openai: ## Run the JavaScript OpenAI-compatible chat example.
	cd examples/js && npm install && node openai-compat.mjs

py-chat: ## Run the Python chat example.
	cd examples/python && python3 -m pip install -r requirements.txt && python3 chat.py

demo: install ## Install, download starter models, serve, then health check.
	$(MAKE) models PROFILE=starter
	$(MAKE) serve
	$(MAKE) health

clean: ## Remove local example dependencies and scratch files.
	rm -rf examples/js/node_modules .foundry-local-scratch

uninstall: ## Uninstall Azure AI Foundry Local.
	bash scripts/uninstall-mac.sh
