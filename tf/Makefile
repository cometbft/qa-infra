ifndef DO_INSTANCE_TAGNAME
	$(error DO_INSTANCE_TAGNAME is not set)
endif

ifndef EPHEMERAL_SIZE
	$(error EPHEMERAL_SIZE is not set)
endif

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
		-var='ephemeral_size=$(EPHEMERAL_SIZE)' \
		-var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]' \
		-var='instance_names=[$(INSTANCE_NAMES)]' && \
	terraform validate && \
	terraform apply \
		-parallelism=50 \
		-var='testnet_size=$(TESTNET_SIZE)' \
		-var='ephemeral_size=$(EPHEMERAL_SIZE)' \
		-var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]' \
		-var='instance_names=[$(INSTANCE_NAMES)]'

.PHONY: destroy
destroy: terraform.tfvars
	terraform destroy \
		-parallelism=50 \
		-var='testnet_size=$(TESTNET_SIZE)' \
		-var='ephemeral_size=$(EPHEMERAL_SIZE)' \
		-var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]' \
		-var='instance_names=[$(INSTANCE_NAMES)]'
