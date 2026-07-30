# Makefile — docs / diagram helpers for terraform-multicloud-hub-spoke
# Author: Md Irshad — Senior Cloud & AI Platform Engineer
#
# These targets ONLY generate documentation artifacts. They never run
# `terraform apply` and require no cloud credentials.

DIAGRAMS_DIR := docs/diagrams
DEV          := examples/dev

.PHONY: help diagrams graph validate fmt lint clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

diagrams: ## Render architecture.png + workflow.png (needs Python + Graphviz "dot")
	pip install -r $(DIAGRAMS_DIR)/requirements.txt
	cd $(DIAGRAMS_DIR) && python architecture.py && python workflow.py

graph: ## Render Terraform resource graph -> docs/diagrams/tf-graph.png (needs terraform init + Graphviz)
	terraform -chdir=$(DEV) init -backend=false -input=false
	terraform -chdir=$(DEV) graph | dot -Tpng > $(DIAGRAMS_DIR)/tf-graph.png

fmt: ## terraform fmt (check, recursive) — same as CI
	terraform fmt -check -recursive

validate: ## init -backend=false + validate the dev example (no credentials)
	terraform -chdir=$(DEV) init -backend=false -input=false
	terraform -chdir=$(DEV) validate

lint: ## tflint across all modules (needs tflint)
	tflint --init
	tflint --recursive

clean: ## Remove local terraform init artifacts and python caches
	rm -rf $(DEV)/.terraform $(DEV)/.terraform.lock.hcl $(DIAGRAMS_DIR)/__pycache__
