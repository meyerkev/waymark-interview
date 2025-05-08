DEFAULT_AWS_PROFILE ?= default

.PHONY: all

all:  ## Initialize, plan, and apply the Terraform setup
	$(MAKE) init
	$(MAKE) apply

# IF TFSTATE_REGION is not set, just run terraform init
.PHONY: init
init:  ## Initialize the Terraform setup
	@export AWS_PROFILE=$(DEFAULT_AWS_PROFILE); \
	if [ -z "$(TFSTATE_BUCKET)" ] || [ -z "$(TFSTATE_KEY)" ] || [ -z "$(TFSTATE_REGION)" ]; then \
		terraform init; \
	else \
		terraform init -backend-config="bucket=$(TFSTATE_BUCKET)" \
			-backend-config="key=$(TFSTATE_KEY)" \
			-backend-config="region=$(TFSTATE_REGION)"; \
	fi

.PHONY: plan
plan:  ## Plan the changes
	@export AWS_PROFILE=$(DEFAULT_AWS_PROFILE); \
	terraform plan -out=plan.tfplan

.PHONY: apply
apply: ## Apply the plan
	@export AWS_PROFILE=$(DEFAULT_AWS_PROFILE); \
	if [ -f plan.tfplan ]; then \
		terraform apply plan.tfplan; \
	else \
		terraform apply; \
	fi
	rm -f plan.tfplan

.PHONY: destroy
destroy:  ## Destroy the setup
	@export AWS_PROFILE=$(DEFAULT_AWS_PROFILE); \
	terraform destroy

.PHONY: enable-uploads
enable-uploads:  ## Enable uploads to the bucket
	@export AWS_PROFILE=$(DEFAULT_AWS_PROFILE); \
	terraform output -raw aws_configure_command

.PHONY: upload
upload: ## Upload a file to the bucket
	@export OLD_AWS_PROFILE=$$AWS_PROFILE; \
	export AWS_PROFILE=$(DEFAULT_AWS_PROFILE); \
	cmd=$$(terraform output -raw aws_s3_upload_command); \
	echo "Running: $$cmd"; \
	export AWS_PROFILE=$$OLD_AWS_PROFILE; \
	eval "$$cmd"; \

.PHONY: cleanup
cleanup:  ## Cleanup everything created by this setup
	@export AWS_PROFILE=$(DEFAULT_AWS_PROFILE); \
	cmd=$$(terraform output -raw aws_s3_delete_all_command); \
	echo "Running: $$cmd"; \
	eval "$$cmd"
	$(MAKE) destroy

.PHONY: help
help:  ## Show this help
	@echo "Available targets:"
	@echo "----------------"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""