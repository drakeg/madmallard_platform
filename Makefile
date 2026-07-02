ENV ?= dev
TF_DIR := terraform/environments/$(ENV)

.PHONY: help tf-init tf-fmt tf-validate tf-plan tf-apply tf-destroy tf-output app-build app-up app-down app-logs

help:
	@echo "Mad Mallard Platform commands"
	@echo ""
	@echo "Terraform:"
	@echo "  make tf-init ENV=dev"
	@echo "  make tf-plan ENV=dev"
	@echo "  make tf-apply ENV=dev"
	@echo "  make tf-output ENV=dev"
	@echo "  make tf-destroy ENV=dev"
	@echo ""
	@echo "Django/Docker local app:"
	@echo "  make app-build"
	@echo "  make app-up"
	@echo "  make app-down"
	@echo "  make app-logs"

tf-init:
	cd $(TF_DIR) && terraform init

tf-fmt:
	terraform fmt -recursive terraform

tf-validate:
	cd $(TF_DIR) && terraform validate

tf-plan:
	cd $(TF_DIR) && terraform plan

tf-apply:
	cd $(TF_DIR) && terraform apply

tf-destroy:
	cd $(TF_DIR) && terraform destroy

tf-output:
	cd $(TF_DIR) && terraform output

app-build:
	cd app && docker compose build

app-up:
	cd app && docker compose up -d

app-down:
	cd app && docker compose down

app-logs:
	cd app && docker compose logs -f
