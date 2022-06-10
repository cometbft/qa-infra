TESTNET_SIZE=$(shell grep '^\[node.*\]' -c ../testnet.toml)
INSTANCE_NAMES=$(shell grep '^\[node.*\]' ../testnet.toml | sed -e 's/^\[node\.\(.*\)]/"\1"/' | sort | paste -s -d, -)

.PHONY: init
init:
	terraform init

.PHONY: apply
apply:
	terraform refresh \
		-var='testnet_size=$(TESTNET_SIZE)' \
		-var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]' \
		-var='instance_names=[$(INSTANCE_NAMES)]'\
		-var='do_token=$(DO_TOKEN)' \
		-var='ssh_keys=$(DO_SSH_KEYS)' && \
	terraform validate && \
	terraform apply \
		-var='testnet_size=$(TESTNET_SIZE)' \
		-var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]' \
		-var='instance_names=[$(INSTANCE_NAMES)]'\
		-var='do_token=$(DO_TOKEN)' \
		-var='ssh_keys=$(DO_SSH_KEYS)'

.PHONY: destroy
destroy:
	terraform destroy \
		-var='testnet_size=$(TESTNET_SIZE)' \
		-var='instance_tags=["$(DO_INSTANCE_TAGNAME)"]' \
		-var='instance_names=[$(INSTANCE_NAMES)]'\
		-var='do_token=$(DO_TOKEN)' \
		-var='ssh_keys=$(DO_SSH_KEYS)'

