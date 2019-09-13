.DEFAULT_GOAL := help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

init: dist-exists ## Create Hacienda settings file
	cp --no-clobber Hacienda.yml.dist Hacienda.yml ## Create Hacienda settings file

sites: dist-exists ## Provision nginx sites only
	vagrant provision --provision-with sites

dist-exists: Hacienda.yml.dist
