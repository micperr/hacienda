.DEFAULT_GOAL := help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

init: dist-exists ## Create Hacienda settings file
	cp --no-clobber Hacienda.yml.dist Hacienda.yml ## Create Hacienda settings file

up: dist-exists ## Start VM
	vagrant up

upr: dist-exists ## Start and provision VM
	vagrant up --provision

p: dist-exists ## Provision VM
	vagrant provision

r: dist-exists ## Reload VM
	vagrant reload

s: ## SSH into VM
	vagrant ssh

h: ## Halt VM
	./.venv/bin/python server.py build

d: ## Destroy VM
	vagrant destroy

dist-exists: Hacienda.yml.dist
