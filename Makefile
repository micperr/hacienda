.DEFAULT_GOAL := help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

init: dist-exists ## Create Hacienda settings file
	cp --no-clobber Hacienda.yml.dist Hacienda.yml ## Create Hacienda settings file

up: dist-exists ## Start VM
	vagrant up

up-and-provision: dist-exists ## Start and provision VM
	vagrant up --provision

provision: dist-exists ## Provision VM
	vagrant provision

reload: dist-exists ## Reload VM
	vagrant reload

ssh: ## SSH into VM
	vagrant ssh

halt: ## Halt VM
	./.venv/bin/python server.py build

destroy: ## Destroy VM
	vagrant destroy

dist-exists: Hacienda.yml.dist
