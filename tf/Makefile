DO_INSTANCE_TAGNAME ?= v035-testnet
TESTNET_SIZE=$(shell grep '^\[node.*\]' -c ../testnet.toml)
INSTANCE_NAMES=$(shell grep '^\[node.*\]' ../testnet.toml | sed -e 's/^\[node\.\(.*\)]/"\1"/' | sort | paste -s -d, -)

.PHONY: init
init:
	terraform init

terraform.tfvars:
ifeq (,$(wildcard ./terraform.tfvars))
	$(error missing "terraform.tfvars" in "tf" directory - see the README for more details)
endif

.PHONY: apply
apply: terraform.tfvars
	terraform refresh \
		-var='testnet_size=$(TESTNET_SIZE)' \
		-var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]' \
		-var='instance_names=[$(INSTANCE_NAMES)]' && \
	terraform validate && \
	terraform apply \
		-auto-approve \
		-var='testnet_size=$(TESTNET_SIZE)' \
		-var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]' \
		-var='instance_names=[$(INSTANCE_NAMES)]'

.PHONY: destroy
destroy: terraform.tfvars
	terraform destroy \
		-auto-approve \
		-var='testnet_size=$(TESTNET_SIZE)' \
		-var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]' \
		-var='instance_names=[$(INSTANCE_NAMES)]'

