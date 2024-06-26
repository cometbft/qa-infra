include experiment.mk

ifndef MANIFEST_PATH
	$(error MANIFEST_PATH is not set)
endif

ifndef VERSION_TAG
	$(error VERSION_TAG is not set)
endif

ifndef VERSION_WEIGHT
	$(error VERSION_WEIGHT is not set)
endif

ifndef EPHEMERAL_SIZE
	$(error EPHEMERAL_SIZE is not set)
endif

ifeq ($(VERSION_WEIGHT), 0)
	$(error VERSION_WEIGHT must be non-zero)
endif

RUNNER_COMMIT_HASH ?= $(VERSION_TAG)
LOAD_RUNNER_CMD=go run github.com/cometbft/cometbft/test/e2e/runner@$(RUNNER_COMMIT_HASH)
export DO_INSTANCE_TAGNAME
export DO_VPC_SUBNET
export EPHEMERAL_SIZE
export MANIFEST_PATH
export VERSION_WEIGHT
export VERSION2_WEIGHT

# Set it to "all" to retrieve from all hosts
# Set it to "any" to retrieve from one full node
# Set it to the exact name of a validator to retrieve from it
RETRIEVE_TARGET_HOST ?= any
EXPERIMENT_DIR ?= $(shell date "+%Y-%m-%d-%H_%M_%S%N")

TESTNET_DIR=./ansible/testnet # created by terraform

.PHONY: terraform-init
terraform-init:
	$(MAKE) -C ./tf/ init

.PHONY: terraform-apply
terraform-apply:
	$(MAKE) -C ./tf/ apply

.PHONY: configgen
configgen:
	./script/configgen.sh $(RUNNER_COMMIT_HASH) $(MANIFEST) $(EPHEMERAL_SIZE) $(TESTNET_DIR)

.PHONY: ansible-install
ansible-install:
	ansible-playbook ./ansible/testapp-install.yaml -e "version_tag=$(VERSION_TAG)"
ifneq ($(VERSION2_WEIGHT), 0)
	ansible-playbook ./ansible/testapp-update.yaml -e "version_tag=$(VERSION2_TAG)" --limit validators2
endif
	$(MAKE) loadrunners-init

.PHONY: prometheus-init
prometheus-init:
	ansible-playbook ./ansible/prometheus-init.yaml

.PHONY: loadrunners-init
loadrunners-init:
	ansible-playbook ./ansible/loader-init.yaml -e "version_tag=$(VERSION_TAG)"

.PHONY: start-network
start-network:
	$(LOAD_RUNNER_CMD) start \
		-f ./ansible/testnet/manifest.toml --infrastructure-type digital-ocean --infrastructure-data ansible/testnet/infrastructure-data.json \
		--testnet-dir $(TESTNET_DIR)

.PHONY: stop-network
stop-network:
	$(LOAD_RUNNER_CMD) stop \
		-f ./ansible/testnet/manifest.toml --infrastructure-type digital-ocean --infrastructure-data ansible/testnet/infrastructure-data.json \
		--testnet-dir $(TESTNET_DIR)

.PHONY: runload
runload:
	ansible-playbook ./ansible/loader-run.yaml \
		-e endpoints=`./ansible/scripts/get-endpoints.sh` \
		-e connections=$(LOAD_CONNECTIONS) \
		-e time_seconds=$(LOAD_TOTAL_TIME) \
		-e tx_per_second=$(LOAD_TX_RATE) \
		-e iterations=$(ITERATIONS)

.PHONY: restart
restart: loadrunners-init
	ansible-playbook ./ansible/testapp-update.yaml -e "version_tag=$(VERSION_TAG)"
ifneq ($(VERSION2_WEIGHT), 0)
	ansible-playbook ./ansible/testapp-update.yaml -e "version_tag=$(VERSION2_TAG)" --limit validators2
endif
	ansible-playbook ./ansible/prometheus-restart.yaml
	ansible-playbook ./ansible/testapp-reinit.yaml

.PHONY: rotate
rotate:
	./script/rotate.sh $(TESTNET_DIR) \
		`ansible all --list-hosts -i ./ansible/hosts --limit ephemeral | tail +2 | paste -s -d, - | tr -d ' '`

.PHONY: perturb-nodes
perturb-nodes:
	$(LOAD_RUNNER_CMD) perturb \
		-f ./ansible/testnet/manifest.toml --infrastructure-type digital-ocean --infrastructure-data ansible/testnet/infrastructure-data.json
		--testnet-dir $(TESTNET_DIR)

.PHONY: retrieve-blockstore
retrieve-blockstore:
	mkdir -p "./experiments/$(EXPERIMENT_DIR)"
ifeq ($(RETRIEVE_TARGET_HOST), any)
	last_val=$$(ansible --list-hosts validators | tail -1 | sed  "s/ //g") && \
	retrieve_target_host=$$(ansible-inventory -y --host $$last_val | grep 'name' | cut -d ' ' -f2) && \
	ansible-playbook ./ansible/retrieve-blockstore.yaml -e "dir=../experiments/$(EXPERIMENT_DIR)/" -e "target_host=$$retrieve_target_host"
else
	ansible-playbook ./ansible/retrieve-blockstore.yaml -e "dir=../experiments/$(EXPERIMENT_DIR)/" -e "target_host=$(RETRIEVE_TARGET_HOST)"
endif

.PHONY: retrieve-prometheus-data
retrieve-prometheus-data:
	mkdir -p "./experiments/$(EXPERIMENT_DIR)"; \
	ansible-playbook ./ansible/retrieve-prometheus.yaml --limit `ansible --list-hosts prometheus | tail -1 | sed  's/ //g'` -e "dir=../experiments/$(EXPERIMENT_DIR)/"

.PHONY: retrieve-data
retrieve-data: retrieve-prometheus-data retrieve-blockstore

.PHONY: terraform-destroy
terraform-destroy:
	$(MAKE) -C ./tf/ destroy
