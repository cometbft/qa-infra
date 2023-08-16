ifndef DO_INSTANCE_TAGNAME
	$(error DO_INSTANCE_TAGNAME is not set)
endif

ifndef EPHEMERAL_SIZE
	$(error EPHEMERAL_SIZE is not set)
endif

ifndef DO_VPC_SUBNET
	$(error DO_VPC_SUBNET is not set)
endif

EPHEMERAL_NAMES=$(shell for i in $$(seq 1 `expr $(EPHEMERAL_SIZE)`); do printf "\"ephemeral%03d\"\n" $$i; done | paste -s -d, -)
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
		-var='ephemeral_names=[$(EPHEMERAL_NAMES)]' \
		-var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]' \
		-var='instance_names=[$(INSTANCE_NAMES)]' \
		-var='vpc_subnet=$(DO_VPC_SUBNET)' \

	terraform validate && \
	terraform apply \
		-parallelism=12 \
		-var='testnet_size=$(TESTNET_SIZE)' \
		-var='ephemeral_size=$(EPHEMERAL_SIZE)' \
		-var='ephemeral_names=[$(EPHEMERAL_NAMES)]' \
		-var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]' \
		-var='instance_names=[$(INSTANCE_NAMES)]' \
		-var='vpc_subnet=$(DO_VPC_SUBNET)' \


.PHONY: destroy
destroy: terraform.tfvars
	terraform destroy \
		-parallelism=12 \
		-var='testnet_size=$(TESTNET_SIZE)' \
		-var='ephemeral_size=$(EPHEMERAL_SIZE)' \
		-var='ephemeral_names=[$(EPHEMERAL_NAMES)]' \
		-var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]' \
		-var='instance_names=[$(INSTANCE_NAMES)]' \
		-var='vpc_subnet=$(DO_VPC_SUBNET)' \
